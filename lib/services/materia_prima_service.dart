import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/materia_prima.dart';

class MateriaPrimaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'Materia_prima';

  // Obtener todas las materias primas
  Future<List<MateriaPrima>> obtenerTodas() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('nombre');

      return (response as List)
          .map((json) => MateriaPrima.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener materias primas: $e');
    }
  }

  // Obtener materia prima por ID
  Future<MateriaPrima?> obtenerPorId(int id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? MateriaPrima.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al obtener materia prima: $e');
    }
  }

  // Obtener materias primas por categoría
  Future<List<MateriaPrima>> obtenerPorCategoria(int idCategoria) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id_categoria_mp', idCategoria)
          .order('nombre');

      return (response as List)
          .map((json) => MateriaPrima.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener materias primas por categoría: $e');
    }
  }

  // Crear nueva materia prima
  Future<MateriaPrima> crear(MateriaPrima materiaPrima) async {
    try {
      // Validar antes de crear
      final errores = materiaPrima.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }

      // Verificar si ya existe una materia prima con el mismo nombre
      final existente = await _verificarNombreExistente(materiaPrima.nombre);
      if (existente) {
        throw Exception('Ya existe una materia prima con ese nombre');
      }

      final response = await _supabase
          .from(_tableName)
          .insert(materiaPrima.toJson())
          .select()
          .single();

      return MateriaPrima.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear materia prima: $e');
    }
  }

  // Actualizar materia prima
  Future<MateriaPrima> actualizar(MateriaPrima materiaPrima) async {
    try {
      if (materiaPrima.id == null) {
        throw Exception('El ID de la materia prima es requerido para actualizar');
      }

      // Validar antes de actualizar
      final errores = materiaPrima.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }

      // Verificar si ya existe otra materia prima con el mismo nombre
      final existente = await _verificarNombreExistente(materiaPrima.nombre, materiaPrima.id);
      if (existente) {
        throw Exception('Ya existe otra materia prima con ese nombre');
      }

      final response = await _supabase
          .from(_tableName)
          .update(materiaPrima.toJson())
          .eq('id', materiaPrima.id!)
          .select()
          .single();

      return MateriaPrima.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar materia prima: $e');
    }
  }

  // Eliminar materia prima
  Future<void> eliminar(int id) async {
    try {
      // Verificar si la materia prima está siendo utilizada
      final enUso = await _verificarEnUso(id);
      if (enUso) {
        throw Exception('No se puede eliminar la materia prima porque está siendo utilizada en recetas o compras');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar materia prima: $e');
    }
  }
  // Actualizar stock
  Future<MateriaPrima> actualizarStock(int id, int nuevoStock) async {
    try {
      if (nuevoStock < 0) {
        throw Exception('El stock no puede ser negativo');
      }

      final response = await _supabase
          .from(_tableName)
          .update({'stock': nuevoStock})
          .eq('id', id)
          .select()
          .single();

      return MateriaPrima.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar stock: $e');
    }
  }
  // Agregar stock (compra)
  Future<MateriaPrima> agregarStock(int id, int cantidad) async {
    try {
      if (cantidad <= 0) {
        throw Exception('La cantidad debe ser mayor a 0');
      }

      final materiaPrima = await obtenerPorId(id);
      if (materiaPrima == null) {
        throw Exception('Materia prima no encontrada');
      }

      final nuevoStock = materiaPrima.stock + cantidad;
      return await actualizarStock(id, nuevoStock);
    } catch (e) {
      throw Exception('Error al agregar stock: $e');
    }
  }
  // Reducir stock (uso en producción)
  Future<MateriaPrima> reducirStock(int id, int cantidad) async {
    try {
      if (cantidad <= 0) {
        throw Exception('La cantidad debe ser mayor a 0');
      }

      final materiaPrima = await obtenerPorId(id);
      if (materiaPrima == null) {
        throw Exception('Materia prima no encontrada');
      }

      final nuevoStock = materiaPrima.stock - cantidad;
      if (nuevoStock < 0) {
        throw Exception('Stock insuficiente. Stock actual: ${materiaPrima.stock}, Cantidad solicitada: $cantidad');
      }

      return await actualizarStock(id, nuevoStock);
    } catch (e) {
      throw Exception('Error al reducir stock: $e');
    }
  }

  // Buscar materias primas
  Future<List<MateriaPrima>> buscar(String termino) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .or('nombre.ilike.%$termino%,descripcion.ilike.%$termino%')
          .order('nombre');

      return (response as List)
          .map((json) => MateriaPrima.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar materias primas: $e');
    }
  }

  // Obtener materias primas con stock bajo
  Future<List<MateriaPrima>> obtenerStockBajo([double? limite]) async {
    try {
      limite ??= 10.0; // Límite por defecto

      final response = await _supabase
          .from(_tableName)
          .select()
          .lt('stock', limite)
          .order('stock');

      return (response as List)
          .map((json) => MateriaPrima.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener materias primas con stock bajo: $e');
    }
  }

  // Verificar si existe una materia prima con el mismo nombre
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

  // Verificar si la materia prima está siendo utilizada
  Future<bool> _verificarEnUso(int id) async {
    try {
      // Verificar en recetas
      final recetas = await _supabase
          .from('receta')
          .select('id')
          .contains('id_materias_primas', [id])
          .maybeSingle();

      if (recetas != null) return true;

      // Verificar en compras
      final compras = await _supabase
          .from('compras')
          .select('id')
          .eq('id_materia_prima', id)
          .maybeSingle();

      return compras != null;
    } catch (e) {
      return false;
    }
  }  // Obtener estadísticas
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final total = await _supabase
          .from(_tableName)
          .select('id');

      final stockBajo = await _supabase
          .from(_tableName)
          .select('id')
          .lt('stock', 10);

      final valorTotal = await _supabase
          .from(_tableName)
          .select('stock, siVendePrecio')
          .not('siVendePrecio', 'is', null);

      double valorInventario = 0;
      for (final item in valorTotal) {
        final stock = (item['stock'] as num).toInt();
        final precio = (item['siVendePrecio'] as num).toDouble();
        valorInventario += stock * precio;
      }

      return {
        'total': (total as List).length,
        'stockBajo': (stockBajo as List).length,
        'valorInventario': valorInventario,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
