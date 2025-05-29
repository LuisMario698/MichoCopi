import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/proveedor.dart';

class ProveedorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'proveedores';

  // Obtener todos los proveedores
  Future<List<Proveedor>> obtenerTodos() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('nombre');

      return (response as List)
          .map((json) => Proveedor.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener proveedores: $e');
    }
  }

  // Obtener proveedor por ID
  Future<Proveedor?> obtenerPorId(int id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Proveedor.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al obtener proveedor: $e');
    }
  }

  // Obtener proveedores por categoría
  Future<List<Proveedor>> obtenerPorCategoria(int idCategoria) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id_categoria_p', idCategoria)
          .order('nombre');

      return (response as List)
          .map((json) => Proveedor.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener proveedores por categoría: $e');
    }
  }

  // Crear nuevo proveedor
  Future<Proveedor> crear(Proveedor proveedor) async {
    try {
      // Validar antes de crear
      final errores = proveedor.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }      // Verificar si ya existe un proveedor con el mismo nombre
      final existente = await _verificarProveedorExistente(proveedor.nombre);
      if (existente) {
        throw Exception('Ya existe un proveedor con ese nombre');
      }

      final response = await _supabase
          .from(_tableName)
          .insert(proveedor.toJson())
          .select()
          .single();

      return Proveedor.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear proveedor: $e');
    }
  }

  // Actualizar proveedor
  Future<Proveedor> actualizar(Proveedor proveedor) async {
    try {
      if (proveedor.id == null) {
        throw Exception('El ID del proveedor es requerido para actualizar');
      }

      // Validar antes de actualizar
      final errores = proveedor.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }      // Verificar si ya existe otro proveedor con el mismo nombre
      final existente = await _verificarProveedorExistente(
        proveedor.nombre,
        proveedor.id
      );
      if (existente) {
        throw Exception('Ya existe otro proveedor con ese nombre');
      }

      final response = await _supabase
          .from(_tableName)
          .update(proveedor.toJson())
          .eq('id', proveedor.id!)
          .select()
          .single();

      return Proveedor.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar proveedor: $e');
    }
  }

  // Eliminar proveedor
  Future<void> eliminar(int id) async {
    try {
      // Verificar si el proveedor está siendo utilizado
      final enUso = await _verificarEnUso(id);
      if (enUso) {
        throw Exception('No se puede eliminar el proveedor porque tiene compras registradas');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar proveedor: $e');
    }
  }

  // Buscar proveedores
  Future<List<Proveedor>> buscar(String termino) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .or('nombre.ilike.%$termino%,telefono.ilike.%$termino%')
          .order('nombre');

      return (response as List)
          .map((json) => Proveedor.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar proveedores: $e');
    }
  }
  // Verificar si existe un proveedor con el mismo nombre
  Future<bool> _verificarProveedorExistente(String nombre, [int? excluirId]) async {
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

  // Verificar si el proveedor está siendo utilizado
  Future<bool> _verificarEnUso(int id) async {
    try {
      final response = await _supabase
          .from('compras')
          .select('id')
          .eq('id_proveedor', id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Obtener estadísticas del proveedor
  Future<Map<String, dynamic>> obtenerEstadisticas(int id) async {
    try {
      final compras = await _supabase
          .from('compras')
          .select('cantidad, precio')
          .eq('id_proveedor', id);      int totalCompras = 0;
      double montoTotal = 0;

      totalCompras = (compras as List).length;
      for (final compra in compras as List) {
        final cantidad = (compra['cantidad'] as num?)?.toDouble() ?? 0;
        final precio = (compra['precio'] as num?)?.toDouble() ?? 0;
        montoTotal += cantidad * precio;
      }

      return {
        'totalCompras': totalCompras,
        'montoTotal': montoTotal,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas del proveedor: $e');
    }
  }

  // Obtener proveedores más activos
  Future<List<Map<String, dynamic>>> obtenerProveedoresMasActivos([int limite = 10]) async {
    try {
      final response = await _supabase.rpc('obtener_proveedores_mas_activos', 
          params: {'limite_param': limite});

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback si no existe el stored procedure
      final proveedores = await obtenerTodos();
      List<Map<String, dynamic>> proveedoresConEstadisticas = [];

      for (final proveedor in proveedores) {
        final estadisticas = await obtenerEstadisticas(proveedor.id!);
        proveedoresConEstadisticas.add({
          'proveedor': proveedor,
          'totalCompras': estadisticas['totalCompras'],
          'montoTotal': estadisticas['montoTotal'],
        });
      }

      // Ordenar por total de compras
      proveedoresConEstadisticas.sort((a, b) => 
          (b['totalCompras'] as int).compareTo(a['totalCompras'] as int));

      return proveedoresConEstadisticas.take(limite).toList();
    }
  }
}