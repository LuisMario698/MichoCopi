import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria_mp.dart';

class CategoriaMpService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'Categoria_mp';

  // Obtener todas las categorías de materia prima
  Future<List<CategoriaMp>> obtenerTodas() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('nombre');

      print('📝 Raw response from Supabase: $response'); // Debug print

      return (response as List).map((json) {
        print('📝 Processing JSON item: $json'); // Debug print for each item
        try {
          final categoria = CategoriaMp.fromJson(json);
          print(
            '✅ Successfully parsed category: ${categoria.nombre}',
          ); // Success debug print
          return categoria;
        } catch (e, stackTrace) {
          print('❌ Error parsing category JSON: $e'); // Error debug print
          print('Stack trace: $stackTrace');
          throw Exception('Error al procesar categoría: $e\nDatos: $json');
        }
      }).toList();
    } catch (e) {
      print('❌ Error in obtenerTodas: $e'); // Error debug print
      throw Exception('Error al obtener categorías de materia prima: $e');
    }
  }

  // Obtener categoría por ID
  Future<CategoriaMp?> obtenerPorId(int id) async {
    try {
      final response =
          await _supabase.from(_tableName).select().eq('id', id).maybeSingle();

      return response != null ? CategoriaMp.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al obtener categoría de materia prima: $e');
    }
  }

  // Crear nueva categoría
  Future<CategoriaMp> crear(CategoriaMp categoria) async {
    try {
      // Validar antes de crear
      final errores = categoria.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }

      // Verificar si ya existe una categoría con el mismo nombre
      final existente = await _verificarNombreExistente(categoria.nombre);
      if (existente) {
        throw Exception('Ya existe una categoría con ese nombre');
      }

      final response =
          await _supabase
              .from(_tableName)
              .insert(categoria.toJson())
              .select()
              .single();

      return CategoriaMp.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear categoría de materia prima: $e');
    }
  }

  // Actualizar categoría
  Future<CategoriaMp> actualizar(CategoriaMp categoria) async {
    try {
      if (categoria.id == null) {
        throw Exception('El ID de la categoría es requerido para actualizar');
      }

      // Validar antes de actualizar
      final errores = categoria.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }

      // Verificar si ya existe otra categoría con el mismo nombre
      final existente = await _verificarNombreExistente(
        categoria.nombre,
        categoria.id,
      );
      if (existente) {
        throw Exception('Ya existe otra categoría con ese nombre');
      }

      final response =
          await _supabase
              .from(_tableName)
              .update(categoria.toJson())
              .eq('id', categoria.id!)
              .select()
              .single();

      return CategoriaMp.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar categoría de materia prima: $e');
    }
  }

  // Eliminar categoría
  Future<void> eliminar(int id) async {
    try {
      // Verificar si la categoría está siendo utilizada
      final enUso = await _verificarEnUso(id);
      if (enUso) {
        throw Exception(
          'No se puede eliminar la categoría porque está siendo utilizada por materias primas',
        );
      }

      await _supabase.from(_tableName).delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría de materia prima: $e');
    }
  }

  // Buscar categorías por nombre
  Future<List<CategoriaMp>> buscarPorNombre(String nombre) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .ilike('nombre', '%$nombre%')
          .order('nombre');

      return (response as List)
          .map((json) => CategoriaMp.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar categorías de materia prima: $e');
    }
  }

  // Verificar si existe una categoría con el mismo nombre
  Future<bool> _verificarNombreExistente(
    String nombre, [
    int? excluirId,
  ]) async {
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

  // Verificar si la categoría está siendo utilizada
  Future<bool> _verificarEnUso(int id) async {
    try {
      final response =
          await _supabase
              .from('Materia_prima')
              .select('id')
              .eq('id_categoria_mp', id)
              .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Obtener estadísticas de la categoría
  Future<Map<String, dynamic>> obtenerEstadisticas(int id) async {
    try {
      final materiaPrimaCount = await _supabase
          .from('Materia_prima')
          .select('id')
          .eq('id_categoria_mp', id);

      return {'totalMateriasPrimas': (materiaPrimaCount as List).length};
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Obtener nombre de categoría por ID
  Future<String> obtenerNombreCategoria(int id) async {
    try {
      final categoria = await obtenerPorId(id);
      return categoria?.nombre ?? 'Categoría no encontrada';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
