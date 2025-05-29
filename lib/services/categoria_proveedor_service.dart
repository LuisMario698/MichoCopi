import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria_proveedor.dart';

class CategoriaProveedorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'categoria_proveedor';

  // Obtener todas las categorías
  Future<List<CategoriaProveedor>> obtenerTodas() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('nombre');

      return (response as List)
          .map((json) => CategoriaProveedor.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener categorías de proveedor: $e');
    }
  }

  // Obtener categoría por ID
  Future<CategoriaProveedor?> obtenerPorId(int id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? CategoriaProveedor.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al obtener categoría de proveedor: $e');
    }
  }

  // Crear nueva categoría
  Future<CategoriaProveedor> crear(CategoriaProveedor categoria) async {
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

      final response = await _supabase
          .from(_tableName)
          .insert(categoria.toJson())
          .select()
          .single();

      return CategoriaProveedor.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear categoría de proveedor: $e');
    }
  }

  // Actualizar categoría
  Future<CategoriaProveedor> actualizar(CategoriaProveedor categoria) async {
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
      final existente = await _verificarNombreExistente(categoria.nombre, categoria.id);
      if (existente) {
        throw Exception('Ya existe otra categoría con ese nombre');
      }

      final response = await _supabase
          .from(_tableName)
          .update(categoria.toJson())
          .eq('id', categoria.id!)
          .select()
          .single();

      return CategoriaProveedor.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar categoría de proveedor: $e');
    }
  }

  // Eliminar categoría
  Future<void> eliminar(int id) async {
    try {
      // Verificar si la categoría está siendo utilizada
      final enUso = await _verificarEnUso(id);
      if (enUso) {
        throw Exception('No se puede eliminar la categoría porque está siendo utilizada por proveedores');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría de proveedor: $e');
    }
  }

  // Buscar categorías
  Future<List<CategoriaProveedor>> buscar(String termino) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .or('nombre.ilike.%$termino%,descripcion.ilike.%$termino%')
          .order('nombre');

      return (response as List)
          .map((json) => CategoriaProveedor.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar categorías de proveedor: $e');
    }
  }

  // Verificar si existe una categoría con el mismo nombre
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

  // Verificar si la categoría está siendo utilizada
  Future<bool> _verificarEnUso(int id) async {
    try {
      final response = await _supabase
          .from('proveedores')
          .select('id')
          .eq('id_categoria_p', id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Obtener estadísticas de la categoría
  Future<Map<String, dynamic>> obtenerEstadisticas(int id) async {
    try {      final totalProveedores = await _supabase
          .from('proveedores')
          .select('id')
          .eq('id_categoria_p', id);

      // Obtener número de compras de proveedores de esta categoría
      final compras = await _supabase
          .from('compras')
          .select('id, cantidad, precio')
          .eq('proveedores.id_categoria_p', id);      double montoCompras = 0;
      for (final compra in compras as List) {
        final cantidad = (compra['cantidad'] as num?)?.toDouble() ?? 0;
        final precio = (compra['precio'] as num?)?.toDouble() ?? 0;
        montoCompras += cantidad * precio;
      }return {
        'totalProveedores': (totalProveedores as List).length,
        'totalCompras': (compras as List).length,
        'montoCompras': montoCompras,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Obtener categorías con mayor actividad
  Future<List<Map<String, dynamic>>> obtenerCategoriasActivas([int limite = 5]) async {
    try {
      final response = await _supabase.rpc('obtener_categorias_proveedor_activas', 
          params: {'limite_param': limite});

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback si no existe el stored procedure
      final categorias = await obtenerTodas();
      List<Map<String, dynamic>> categoriasConEstadisticas = [];

      for (final categoria in categorias) {
        if (categoria.id != null) {
          final estadisticas = await obtenerEstadisticas(categoria.id!);
          categoriasConEstadisticas.add({
            'categoria': categoria,
            'totalProveedores': estadisticas['totalProveedores'],
            'montoCompras': estadisticas['montoCompras'],
          });
        }
      }

      // Ordenar por monto de compras
      categoriasConEstadisticas.sort((a, b) => 
          (b['montoCompras'] as double).compareTo(a['montoCompras'] as double));

      return categoriasConEstadisticas.take(limite).toList();
    }
  }
}
