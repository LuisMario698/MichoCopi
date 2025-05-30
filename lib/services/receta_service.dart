import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receta.dart';

class RecetaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'Receta';

  // Obtener todas las recetas
  Future<List<Receta>> obtenerTodas() async {
    try {
      final response = await _supabase.from(_tableName).select();

      return (response as List).map((json) => Receta.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener recetas: $e');
    }
  }

  // Obtener receta por ID
  Future<Receta?> obtenerPorId(int id) async {
    try {
      final response =
          await _supabase.from(_tableName).select().eq('id', id).maybeSingle();

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

      // Verificar que todas las materias primas existan
      await _verificarMateriasPrimasExisten(receta.idsMps);

      final response =
          await _supabase
              .from(_tableName)
              .insert(receta.toJsonForInsert())
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

      // Verificar que todas las materias primas existan
      await _verificarMateriasPrimasExisten(receta.idsMps);

      final response =
          await _supabase
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

  // Obtener detalles de una receta con información de materias primas
  Future<Map<String, dynamic>> obtenerDetallesReceta(int idReceta) async {
    try {
      final receta = await obtenerPorId(idReceta);
      if (receta == null) {
        throw Exception('Receta no encontrada');
      }

      List<Map<String, dynamic>> materiasPrimas = [];

      for (int i = 0; i < receta.idsMps.length; i++) {
        final idMateria = receta.idsMps[i];
        // Usar un valor predeterminado de 1 si no hay cantidades o el índice está fuera de rango
        final cantidad =
            (receta.cantidades.isNotEmpty && i < receta.cantidades.length)
                ? receta.cantidades[i]
                : 1;

        final materiaPrima =
            await _supabase
                .from('Materia_prima')
                .select()
                .eq('id', idMateria)
                .single();

        materiasPrimas.add({
          'id': idMateria,
          'nombre': materiaPrima['nombre'],
          'cantidad': cantidad,
        });
      }

      return {'receta': receta, 'materiasPrimas': materiasPrimas};
    } catch (e) {
      throw Exception('Error al obtener detalles de la receta: $e');
    }
  }

  // Verificar que todas las materias primas existan
  Future<void> _verificarMateriasPrimasExisten(List<int> idsMps) async {
    try {
      if (idsMps.isEmpty) {
        return; // Si no hay materias primas, no hay nada que verificar
      }

      for (final id in idsMps) {
        final materiaPrima =
            await _supabase
                .from('Materia_prima')
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

  // Verificar si la receta está siendo utilizada en productos
  Future<bool> _verificarEnUso(int id) async {
    try {
      final response =
          await _supabase
              .from('Productos')
              .select('id')
              .eq('id_Receta', id)
              .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Eliminar receta
  Future<void> eliminar(int id) async {
    try {
      // Verificar si la receta está siendo utilizada
      final enUso = await _verificarEnUso(id);
      if (enUso) {
        throw Exception(
          'No se puede eliminar la receta porque está siendo utilizada por productos',
        );
      }

      await _supabase.from(_tableName).delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar receta: $e');
    }
  }
}
