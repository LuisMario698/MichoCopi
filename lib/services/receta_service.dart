import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receta.dart';

class RecetaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'receta';

  // Obtener todas las recetas
  Future<List<Receta>> obtenerTodas() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('nombre');

      return (response as List)
          .map((json) => Receta.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener recetas: $e');
    }
  }

  // Obtener receta por ID
  Future<Receta?> obtenerPorId(int id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Receta.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al obtener receta: $e');
    }
  }

  // Crear nueva receta
  Future<Receta> crear(Receta receta) async {
    try {
      // Validar antes de crear
      final errores = receta.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }

      // Verificar si ya existe una receta con el mismo nombre
      final existente = await _verificarNombreExistente(receta.nombre);
      if (existente) {
        throw Exception('Ya existe una receta con ese nombre');
      }

      // Verificar que todas las materias primas existan
      await _verificarMateriasPrimasExisten(receta.idMateriasPrimas);

      final response = await _supabase
          .from(_tableName)
          .insert(receta.toJson())
          .select()
          .single();

      return Receta.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear receta: $e');
    }
  }

  // Actualizar receta
  Future<Receta> actualizar(Receta receta) async {
    try {
      if (receta.id == null) {
        throw Exception('El ID de la receta es requerido para actualizar');
      }

      // Validar antes de actualizar
      final errores = receta.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }

      // Verificar si ya existe otra receta con el mismo nombre
      final existente = await _verificarNombreExistente(receta.nombre, receta.id);
      if (existente) {
        throw Exception('Ya existe otra receta con ese nombre');
      }

      // Verificar que todas las materias primas existan
      await _verificarMateriasPrimasExisten(receta.idMateriasPrimas);

      final response = await _supabase
          .from(_tableName)
          .update(receta.toJson())
          .eq('id', receta.id!)
          .select()
          .single();

      return Receta.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar receta: $e');
    }
  }

  // Eliminar receta
  Future<void> eliminar(int id) async {
    try {
      // Verificar si la receta está siendo utilizada
      final enUso = await _verificarEnUso(id);
      if (enUso) {
        throw Exception('No se puede eliminar la receta porque está siendo utilizada por productos');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar receta: $e');
    }
  }

  // Buscar recetas
  Future<List<Receta>> buscar(String termino) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .or('nombre.ilike.%$termino%,descripcion.ilike.%$termino%')
          .order('nombre');

      return (response as List)
          .map((json) => Receta.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar recetas: $e');
    }
  }

  // Verificar disponibilidad de stock para una receta
  Future<Map<String, dynamic>> verificarDisponibilidadStock(int idReceta, double cantidadAProducir) async {
    try {
      final receta = await obtenerPorId(idReceta);
      if (receta == null) {
        throw Exception('Receta no encontrada');
      }

      List<Map<String, dynamic>> materiasInsuficientes = [];
      bool stockSuficiente = true;

      for (int i = 0; i < receta.idMateriasPrimas.length; i++) {
        final idMateria = receta.idMateriasPrimas[i];
        final cantidadNecesaria = receta.cantidades[i] * cantidadAProducir;

        final materiaPrima = await _supabase
            .from('materia_prima')
            .select('nombre, stock')
            .eq('id', idMateria)
            .single();

        final stockDisponible = (materiaPrima['stock'] as num).toDouble();

        if (stockDisponible < cantidadNecesaria) {
          stockSuficiente = false;
          materiasInsuficientes.add({
            'id': idMateria,
            'nombre': materiaPrima['nombre'],
            'cantidadNecesaria': cantidadNecesaria,
            'stockDisponible': stockDisponible,
            'faltante': cantidadNecesaria - stockDisponible,
          });
        }
      }

      return {
        'stockSuficiente': stockSuficiente,
        'materiasInsuficientes': materiasInsuficientes,
      };
    } catch (e) {
      throw Exception('Error al verificar disponibilidad de stock: $e');
    }
  }

  // Consumir materias primas para producir una receta
  Future<void> consumirMateriasPrimas(int idReceta, double cantidadAProducir) async {
    try {
      final receta = await obtenerPorId(idReceta);
      if (receta == null) {
        throw Exception('Receta no encontrada');
      }

      // Primero verificar que hay stock suficiente
      final disponibilidad = await verificarDisponibilidadStock(idReceta, cantidadAProducir);
      if (!disponibilidad['stockSuficiente']) {
        throw Exception('Stock insuficiente para producir la receta');
      }

      // Consumir las materias primas
      for (int i = 0; i < receta.idMateriasPrimas.length; i++) {
        final idMateria = receta.idMateriasPrimas[i];
        final cantidadAConsumir = receta.cantidades[i] * cantidadAProducir;

        await _supabase.rpc('reducir_stock_materia_prima', params: {
          'id_materia_prima': idMateria,
          'cantidad_reducir': cantidadAConsumir,
        });
      }
    } catch (e) {
      throw Exception('Error al consumir materias primas: $e');
    }
  }

  // Obtener recetas que pueden ser producidas con el stock actual
  Future<List<Map<String, dynamic>>> obtenerRecetasDisponibles() async {
    try {
      final recetas = await obtenerTodas();
      List<Map<String, dynamic>> recetasDisponibles = [];

      for (final receta in recetas) {
        double maxProduccion = double.infinity;
        bool puedeProducir = true;

        for (int i = 0; i < receta.idMateriasPrimas.length; i++) {
          final idMateria = receta.idMateriasPrimas[i];
          final cantidadNecesaria = receta.cantidades[i];

          final materiaPrima = await _supabase
              .from('materia_prima')
              .select('stock')
              .eq('id', idMateria)
              .maybeSingle();

          if (materiaPrima == null) {
            puedeProducir = false;
            break;
          }

          final stockDisponible = (materiaPrima['stock'] as num).toDouble();
          
          if (stockDisponible <= 0 || cantidadNecesaria <= 0) {
            puedeProducir = false;
            break;
          }

          final posibleProduccion = stockDisponible / cantidadNecesaria;
          maxProduccion = maxProduccion > posibleProduccion ? posibleProduccion : maxProduccion;
        }

        if (puedeProducir && maxProduccion > 0) {
          recetasDisponibles.add({
            'receta': receta,
            'maxProduccion': maxProduccion.floor(),
          });
        }
      }

      return recetasDisponibles;
    } catch (e) {
      throw Exception('Error al obtener recetas disponibles: $e');
    }
  }

  // Obtener detalles de una receta con información de materias primas
  Future<Map<String, dynamic>> obtenerDetallesReceta(int idReceta) async {
    try {
      final receta = await obtenerPorId(idReceta);
      if (receta == null) {
        throw Exception('Receta no encontrada');
      }

      List<Map<String, dynamic>> materiasPrimas = [];
      double costoTotal = 0;

      for (int i = 0; i < receta.idMateriasPrimas.length; i++) {
        final idMateria = receta.idMateriasPrimas[i];
        final cantidad = receta.cantidades[i];

        final materiaPrima = await _supabase
            .from('materia_prima')
            .select('nombre, stock, precio')
            .eq('id', idMateria)
            .single();

        final precio = (materiaPrima['precio'] as num?)?.toDouble() ?? 0;
        final costoIngrediente = cantidad * precio;
        costoTotal += costoIngrediente;

        materiasPrimas.add({
          'id': idMateria,
          'nombre': materiaPrima['nombre'],
          'cantidad': cantidad,
          'stock': (materiaPrima['stock'] as num).toDouble(),
          'precio': precio,
          'costo': costoIngrediente,
        });
      }

      return {
        'receta': receta,
        'materiasPrimas': materiasPrimas,
        'costoTotal': costoTotal,
      };
    } catch (e) {
      throw Exception('Error al obtener detalles de la receta: $e');
    }
  }

  // Verificar si existe una receta con el mismo nombre
  Future<bool> _verificarNombreExistente(String nombre, [int? excluirId]) async {
    try {
      var query = _supabase
          .from(_tableName)
          .select('id')
          .ilike('nombre', nombre);

      if (excluirId != null) {
        query = query.neq('id', excluirId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Verificar que todas las materias primas existan
  Future<void> _verificarMateriasPrimasExisten(List<int> idMateriasPrimas) async {
    try {
      for (final id in idMateriasPrimas) {
        final materiaPrima = await _supabase
            .from('materia_prima')
            .select('id')
            .eq('id', id)
            .maybeSingle();

        if (materiaPrima == null) {
          throw Exception('La materia prima con ID $id no existe');
        }
      }
    } catch (e) {
      throw Exception('Error al verificar materias primas: $e');
    }
  }

  // Verificar si la receta está siendo utilizada
  Future<bool> _verificarEnUso(int id) async {
    try {
      final response = await _supabase
          .from('productos')
          .select('id')
          .eq('id_receta', id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
  // Obtener estadísticas de recetas
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final total = await _supabase
          .from(_tableName)
          .select('id');

      final recetasDisponibles = await obtenerRecetasDisponibles();

      return {
        'total': (total as List).length,
        'disponiblesParaProducir': recetasDisponibles.length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}