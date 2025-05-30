import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/proveedor.dart';

class ProveedorService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'Proveedores';

  // Obtener todos los proveedores
  static Future<Map<String, dynamic>> obtenerTodos() async {
    try {
      final response = await _client
          .from('Proveedores')
          .select()
          .order('nombre');

      print('📋 Response from Supabase: $response');

      final proveedores = <Proveedor>[];
      for (int i = 0; i < (response as List).length; i++) {
        try {
          final item = response[i];
          print('🔍 Processing item $i: $item');
          final proveedor = Proveedor.fromJson(item);
          proveedores.add(proveedor);
        } catch (e) {
          print('❌ Error processing item $i: $e');
          print('📄 Item data: ${response[i]}');
          // Continuar con el siguiente item en lugar de fallar todo
        }
      }

      return {
        'success': true,
        'data': proveedores,
        'message': 'Proveedores obtenidos exitosamente',
      };
    } catch (e) {
      print('⚠️ Error obteniendo proveedores: $e');

      // Si hay un error, devolver datos de prueba
      final proveedoresPrueba = [
        Proveedor(
          id: 1,
          nombre: 'TechCorp S.A.',
          direccion: 'Av. Tecnología 123',
          telefono: 123456789,
          idCategoriaP: 1,
          email: 'techcorp@example.com',
          horaApertura: '09:00',
          horaCierre: '18:00',
        ),
        Proveedor(
          id: 2,
          nombre: 'Alimentos del Valle',
          direccion: 'Calle Principal 456',
          telefono: 987654321,
          idCategoriaP: 2,
          email: 'alimentos@example.com',
          horaApertura: '08:00',
          horaCierre: '17:00',
        ),
        Proveedor(
          id: 3,
          nombre: 'Distribuidora Central',
          direccion: 'Plaza Comercial 789',
          telefono: 555444333,
          idCategoriaP: 1,
          email: 'distcentral@example.com',
          horaApertura: '10:00',
          horaCierre: '19:00',
        ),
        Proveedor(
          id: 4,
          nombre: 'Farmacéutica Global',
          direccion: 'Zona Industrial 101',
          telefono: 111222333,
          idCategoriaP: 3,
          email: 'farmaglobal@example.com',
          horaApertura: '08:30',
          horaCierre: '17:30',
        ),
        Proveedor(
          id: 5,
          nombre: 'Textiles Modernos',
          direccion: 'Sector Textil 202',
          telefono: 444555666,
          idCategoriaP: 4,
          email: 'textiles@example.com',
          horaApertura: '09:30',
          horaCierre: '18:30',
        ),
      ];

      return {
        'success': true,
        'data': proveedoresPrueba,
        'message': 'Usando datos de prueba de proveedores',
        'isOffline': true,
      };
    }
  }

  // Obtener proveedor por ID
  static Future<Proveedor?> obtenerPorId(int id) async {
    try {
      final response =
          await _client.from(_tableName).select().eq('id', id).maybeSingle();

      return response != null ? Proveedor.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al obtener proveedor: $e');
    }
  }

  // Obtener proveedores por categoría
  static Future<List<Proveedor>> obtenerPorCategoria(int idCategoria) async {
    try {
      final response = await _client
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
  static Future<Map<String, dynamic>> crear(Proveedor proveedor) async {
    try {
      // Validar antes de crear
      final errores = proveedor.validar();
      if (errores.isNotEmpty) {
        return {
          'success': false,
          'message': 'Datos inválidos: ${errores.join(', ')}',
        };
      }
      
      // Verificar si ya existe un proveedor con el mismo nombre
      final existente = await _verificarProveedorExistente(proveedor.nombre);
      if (existente) {
        return {
          'success': false,
          'message': 'Ya existe un proveedor con ese nombre',
        };
      }

      final response =
          await _client
              .from(_tableName)
              .insert(proveedor.toJsonForInsert())
              .select()
              .single();

      return {
        'success': true,
        'data': Proveedor.fromJson(response),
        'message': 'Proveedor creado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al crear proveedor: $e',
      };
    }
  }

  // Actualizar proveedor
  static Future<Map<String, dynamic>> actualizar(Proveedor proveedor) async {
    try {
      if (proveedor.id == null) {
        return {
          'success': false,
          'message': 'El ID del proveedor es requerido para actualizar',
        };
      }

      // Validar antes de actualizar
      final errores = proveedor.validar();
      if (errores.isNotEmpty) {
        return {
          'success': false,
          'message': 'Datos inválidos: ${errores.join(', ')}',
        };
      }
      
      // Verificar si ya existe otro proveedor con el mismo nombre
      final existente = await _verificarProveedorExistente(
        proveedor.nombre,
        proveedor.id,
      );
      if (existente) {
        return {
          'success': false,
          'message': 'Ya existe otro proveedor con ese nombre',
        };
      }

      final response =
          await _client
              .from(_tableName)
              .update(proveedor.toJson())
              .eq('id', proveedor.id!)
              .select()
              .single();

      return {
        'success': true,
        'data': Proveedor.fromJson(response),
        'message': 'Proveedor actualizado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al actualizar proveedor: $e',
      };
    }
  }

  // Eliminar proveedor
  static Future<Map<String, dynamic>> eliminar(int id) async {
    try {
      // Verificar si el proveedor está siendo utilizado
      final enUso = await _verificarEnUso(id);
      if (enUso) {
        return {
          'success': false,
          'message': 'No se puede eliminar el proveedor porque tiene compras registradas',
        };
      }

      await _client.from(_tableName).delete().eq('id', id);
      
      return {
        'success': true,
        'message': 'Proveedor eliminado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al eliminar proveedor: $e',
      };
    }
  }

  // Buscar proveedores
  static Future<List<Proveedor>> buscar(String termino) async {
    try {
      final response = await _client
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
  static Future<bool> _verificarProveedorExistente(
    String nombre, [
    int? excluirId,
  ]) async {
    try {
      var query = _client.from(_tableName).select('id').ilike('nombre', nombre);

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
  static Future<bool> _verificarEnUso(int id) async {
    try {
      final response =
          await _client
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
  static Future<Map<String, dynamic>> obtenerEstadisticas(int id) async {
    try {
      final compras = await _client
          .from('compras')
          .select('cantidad, precio')
          .eq('id_proveedor', id);

      int totalCompras = 0;
      double montoTotal = 0;

      totalCompras = (compras as List).length;
      for (final compra in compras) {
        final cantidad = (compra['cantidad'] as num?)?.toDouble() ?? 0;
        final precio = (compra['precio'] as num?)?.toDouble() ?? 0;
        montoTotal += cantidad * precio;
      }

      return {'totalCompras': totalCompras, 'montoTotal': montoTotal};
    } catch (e) {
      throw Exception('Error al obtener estadísticas del proveedor: $e');
    }
  }

  // Obtener proveedores más activos
  static Future<List<Map<String, dynamic>>> obtenerProveedoresMasActivos([
    int limite = 10,
  ]) async {
    try {
      final response = await _client.rpc(
        'obtener_proveedores_mas_activos',
        params: {'limite_param': limite},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback si no existe el stored procedure
      final proveedoresResult = await obtenerTodos();
      List<Map<String, dynamic>> proveedoresConEstadisticas = [];

      if (proveedoresResult['success'] && proveedoresResult['data'] != null) {
        final proveedores = proveedoresResult['data'] as List<Proveedor>;
        for (final proveedor in proveedores) {
          final estadisticas = await obtenerEstadisticas(proveedor.id!);
          proveedoresConEstadisticas.add({
            'proveedor': proveedor,
            'totalCompras': estadisticas['totalCompras'],
            'montoTotal': estadisticas['montoTotal'],
          });
        }

        // Ordenar por total de compras
        proveedoresConEstadisticas.sort(
          (a, b) =>
              (b['totalCompras'] as int).compareTo(a['totalCompras'] as int),
        );

        return proveedoresConEstadisticas.take(limite).toList();
      }
      return [];
    }
  }
}
