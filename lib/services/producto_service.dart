import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';

class ProductoService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Crear un nuevo producto
  static Future<Map<String, dynamic>> crearProducto(Producto producto) async {
    try {
      // Obtener el próximo ID disponible
      final siguienteId = await _obtenerSiguienteIdProducto();
      
      // Crear una copia del producto con el ID generado
      final productoConId = Producto(
        id: siguienteId,
        nombre: producto.nombre,
        precio: producto.precio,
        stock: producto.stock,
        categoria: producto.categoria,
        proveedor: producto.proveedor,
        caducidad: producto.caducidad,
      );
      
      final jsonData = productoConId.toJson();
      print('📝 Datos a enviar a Supabase: $jsonData');
      print('🔍 Tipos de datos:');
      jsonData.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });
      
      // Validar que los IDs no sean null
      if (jsonData['categoria'] == null) {
        throw Exception('El ID de la categoría no puede ser null');
      }
      if (jsonData['proveedor'] == null) {
        throw Exception('El ID del proveedor no puede ser null');
      }
      
      print('🚀 Insertando en tabla Productos...');
      
      final response =
          await _client
              .from('Productos')
              .insert(jsonData)
              .select()
              .single();

      print('✅ Respuesta de Supabase: $response');

      return {
        'success': true,
        'data': Producto.fromJson(response),
        'message': 'Producto creado exitosamente',
      };
    } catch (e) {
      print('❌ Error completo en crearProducto: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('❌ Código de error: ${e.code}');
        print('❌ Mensaje: ${e.message}');
        print('❌ Detalles: ${e.details}');
        print('❌ Hint: ${e.hint}');
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al crear el producto: ${e.toString()}',
      };
    }
  }

  // Función auxiliar para obtener el próximo ID de producto
  static Future<int> _obtenerSiguienteIdProducto() async {
    try {
      final response = await _client
          .from('Productos')
          .select('id')
          .order('id', ascending: false)
          .limit(1);
      
      if (response.isEmpty) {
        return 1; // Si no hay productos, empezar con 1
      }
      
      final maxId = response.first['id'] as int;
      return maxId + 1;
    } catch (e) {
      print('⚠️ Error obteniendo siguiente ID de producto: $e');
      // En caso de error, usar timestamp como ID único
      return DateTime.now().millisecondsSinceEpoch % 1000000;
    }
  }

  // Obtener todos los productos
  static Future<Map<String, dynamic>> obtenerProductos() async {
    try {
      final response = await _client
          .from('Productos')
          .select()
          .order('id', ascending: false);

      final productos =
          (response as List).map((item) => Producto.fromJson(item)).toList();

      return {
        'success': true,
        'data': productos,
        'message': 'Productos obtenidos exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al obtener los productos',
      };
    }
  }

  // Obtener producto por ID
  static Future<Map<String, dynamic>> obtenerProductoPorId(int id) async {
    try {
      final response =
          await _client.from('Productos').select().eq('id', id).single();

      return {
        'success': true,
        'data': Producto.fromJson(response),
        'message': 'Producto encontrado',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al buscar el producto',
      };
    }
  }

  // Actualizar producto
  static Future<Map<String, dynamic>> actualizarProducto(
    int id,
    Producto producto,
  ) async {
    try {
      final response =
          await _client
              .from('Productos')
              .update(producto.toJson())
              .eq('id', id)
              .select()
              .single();

      return {
        'success': true,
        'data': Producto.fromJson(response),
        'message': 'Producto actualizado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al actualizar el producto',
      };
    }
  }

  // Eliminar producto
  static Future<Map<String, dynamic>> eliminarProducto(int id) async {
    try {
      await _client.from('Productos').delete().eq('id', id);

      return {'success': true, 'message': 'Producto eliminado exitosamente'};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al eliminar el producto',
      };
    }
  }

  // Verificar si existe un producto con el mismo nombre
  static Future<Map<String, dynamic>> verificarNombreProducto(
    String nombre,
  ) async {
    try {
      final response = await _client
          .from('Productos')
          .select('id')
          .ilike('nombre', nombre)
          .limit(1);

      return {'success': true, 'existe': (response as List).isNotEmpty};
    } catch (e) {
      print('⚠️ Error en verificarNombreProducto: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Verificar si existe una categoría con el mismo nombre
  static Future<Map<String, dynamic>> verificarNombreCategoria(
    String nombre,
  ) async {
    try {
      final response = await _client
          .from('Categoria_producto')
          .select('id')
          .ilike('nombre', nombre)
          .limit(1);

      return {'success': true, 'existe': (response as List).isNotEmpty};
    } catch (e) {
      print('⚠️ Error en verificarNombreCategoria: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Crear una nueva categoría
  static Future<Map<String, dynamic>> crearCategoria(
    Categoria categoria,
  ) async {
    try {
      // Obtener el próximo ID disponible
      final siguienteId = await _obtenerSiguienteIdCategoria();
      
      // Crear una copia de la categoría con el ID generado
      final categoriaConId = Categoria(
        id: siguienteId,
        nombre: categoria.nombre,
        conCaducidad: categoria.conCaducidad,
      );
      
      print('📝 Creando categoría con ID: ${categoriaConId.toJson()}');
      
      final response =
          await _client
              .from('Categoria_producto')
              .insert(categoriaConId.toJson())
              .select()
              .single();

      return {
        'success': true,
        'data': Categoria.fromJson(response),
        'message': 'Categoría creada exitosamente',
      };
    } catch (e) {
      print('⚠️ Error en crearCategoria: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al crear la categoría',
      };
    }
  }

  // Función auxiliar para obtener el próximo ID de categoría
  static Future<int> _obtenerSiguienteIdCategoria() async {
    try {
      final response = await _client
          .from('Categoria_producto')
          .select('id')
          .order('id', ascending: false)
          .limit(1);
      
      if (response.isEmpty) {
        return 1; // Si no hay categorías, empezar con 1
      }
      
      final maxId = response.first['id'] as int;
      return maxId + 1;
    } catch (e) {
      print('⚠️ Error obteniendo siguiente ID: $e');
      // En caso de error, usar timestamp como ID único
      return DateTime.now().millisecondsSinceEpoch % 1000000;
    }
  }

  // Obtener todas las categorías
  static Future<Map<String, dynamic>> obtenerCategorias() async {
    try {
      final response = await _client
          .from('Categoria_producto')
          .select()
          .order('nombre', ascending: true)
          .timeout(const Duration(seconds: 5));

      final categorias =
          (response as List).map((item) => Categoria.fromJson(item)).toList();

      return {
        'success': true,
        'data': categorias,
        'message': 'Categorías obtenidas exitosamente',
      };
    } catch (e) {
      print('⚠️ Error en obtenerCategorias: $e');
      
      // Determinar el tipo de error y mostrar mensaje apropiado
      String errorMessage = 'Error de conexión';
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Operation not permitted')) {
        errorMessage = 'Sin conexión a la base de datos. Usando datos de prueba.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Tiempo de espera agotado. Usando datos de prueba.';
      }
      
      // Retornar datos de prueba en caso de error de conexión
      final categoriasPrueba = [
        Categoria(id: 1, nombre: 'Electrónicos', conCaducidad: false),
        Categoria(id: 2, nombre: 'Alimentos', conCaducidad: true),
        Categoria(id: 3, nombre: 'Medicamentos', conCaducidad: true),
        Categoria(id: 4, nombre: 'Ropa', conCaducidad: false),
        Categoria(id: 5, nombre: 'Bebidas', conCaducidad: true),
        Categoria(id: 6, nombre: 'Limpieza', conCaducidad: false),
        Categoria(id: 7, nombre: 'Cosméticos', conCaducidad: true),
      ];

      return {
        'success': true,
        'data': categoriasPrueba,
        'message': errorMessage,
        'isOffline': true,
      };
    }
  }

  // Obtener todos los proveedores
  static Future<Map<String, dynamic>> obtenerProveedores() async {
    try {
      final response = await _client
          .from('Proveedores')
          .select()
          .order('nombre', ascending: true)
          .timeout(const Duration(seconds: 5));

      final proveedores =
          (response as List).map((item) => Proveedor.fromJson(item)).toList();

      return {
        'success': true,
        'data': proveedores,
        'message': 'Proveedores obtenidos exitosamente',
      };
    } catch (e) {
      print('⚠️ Error en obtenerProveedores: $e');
      
      // Determinar el tipo de error
      String errorMessage = 'Sin conexión a la base de datos. Usando datos de prueba.';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Tiempo de espera agotado. Usando datos de prueba.';
      }
      
      // Retornar datos de prueba en caso de error de conexión
      final proveedoresPrueba = [
        Proveedor(
          id: 1,
          nombre: 'TechCorp S.A.',
          direccion: 'Av. Tecnología 123',
          telefono: 123456789,
        ),
        Proveedor(
          id: 2,
          nombre: 'Alimentos del Valle',
          direccion: 'Calle Principal 456',
          telefono: 987654321,
        ),
        Proveedor(
          id: 3,
          nombre: 'Distribuidora Central',
          direccion: 'Plaza Comercial 789',
          telefono: 555444333,
        ),
        Proveedor(
          id: 4,
          nombre: 'Farmacéutica Global',
          direccion: 'Zona Industrial 101',
          telefono: 111222333,
        ),
        Proveedor(
          id: 5,
          nombre: 'Textiles Modernos',
          direccion: 'Sector Textil 202',
          telefono: 444555666,
        ),
      ];

      return {
        'success': true,
        'data': proveedoresPrueba,
        'message': errorMessage,
        'isOffline': true,
      };
    }
  }

  // Buscar productos por nombre
  static Future<Map<String, dynamic>> buscarProductos(String termino) async {
    try {
      final response = await _client
          .from('Productos')
          .select()
          .ilike('nombre', '%$termino%')
          .order('nombre', ascending: true);

      final productos =
          (response as List).map((item) => Producto.fromJson(item)).toList();

      return {
        'success': true,
        'data': productos,
        'message': 'Búsqueda completada',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error en la búsqueda',
      };
    }
  }

  // Obtener productos con stock bajo (menos de X unidades)
  static Future<Map<String, dynamic>> obtenerProductosStockBajo({
    int limite = 10,
  }) async {
    try {
      final response = await _client
          .from('Productos')
          .select()
          .lt('stock', limite)
          .order('stock', ascending: true);

      final productos =
          (response as List).map((item) => Producto.fromJson(item)).toList();

      return {
        'success': true,
        'data': productos,
        'message': 'Productos con stock bajo obtenidos',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al obtener productos con stock bajo',
      };
    }
  }

  // Actualizar stock de un producto
  static Future<Map<String, dynamic>> actualizarStock(
    int id,
    int nuevoStock,
  ) async {
    try {
      final response =
          await _client
              .from('Productos')
              .update({'stock': nuevoStock})
              .eq('id', id)
              .select()
              .single();

      return {
        'success': true,
        'data': Producto.fromJson(response),
        'message': 'Stock actualizado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al actualizar el stock',
      };
    }
  }
}
