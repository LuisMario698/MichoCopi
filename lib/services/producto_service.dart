import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';

class ProductoService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Crear un nuevo producto
  static Future<Map<String, dynamic>> crearProducto(Producto producto) async {
    try {
      // Validaciones iniciales
      if (producto.nombre.trim().isEmpty) {
        return {
          'success': false,
          'message': 'El nombre del producto es requerido',
        };
      }

      if (producto.precio <= 0) {
        return {
          'success': false,
          'message': 'El precio debe ser mayor a 0',
        };
      }

      if (producto.stock < 0) {
        return {
          'success': false,
          'message': 'El stock no puede ser negativo',
        };
      }

      // Verificar si la categoría existe
      try {
        final categoriaResponse = await _client
            .from('Categoria_producto')
            .select('id, nombre')
            .eq('id', producto.categoria)
            .single();
        print('✅ Categoría verificada: $categoriaResponse');
      } catch (e) {
        print('❌ Error verificando categoría: $e');
        return {
          'success': false,
          'message': 'La categoría seleccionada no existe',
        };
      }

      // Verificar si el proveedor existe
      try {
        final proveedorResponse = await _client
            .from('Proveedores')
            .select('id, nombre')
            .eq('id', producto.proveedor)
            .single();
        print('✅ Proveedor verificado: $proveedorResponse');
      } catch (e) {
        print('❌ Error verificando proveedor: $e');
        return {
          'success': false,
          'message': 'El proveedor seleccionado no existe',
        };
      }

      // Verificar si ya existe un producto con el mismo nombre
      final nombreExists = await verificarNombreProducto(producto.nombre);
      if (nombreExists['success'] && nombreExists['existe']) {
        return {
          'success': false,
          'message': 'Ya existe un producto con este nombre',
        };
      }

      // Preparar datos para inserción
      final productoData = {
        'nombre': producto.nombre.trim(),
        'precio': double.parse(producto.precio.toStringAsFixed(2)),
        'stock': producto.stock,
        'categoria': producto.categoria,
        'proveedor': producto.proveedor,
        if (producto.caducidad != null)
          'caducidad': producto.caducidad!.toIso8601String().split('T')[0],
      };

      print('📝 Datos a enviar a Supabase: $productoData');

      // Insertar el producto
      final response = await _client
          .from('Productos')
          .insert(productoData)
          .select()
          .single();

      print('✅ Producto creado exitosamente en Supabase: $response');

      return {
        'success': true,
        'data': Producto.fromJson(response),
        'message': 'Producto creado exitosamente',
      };
    } catch (e) {
      print('❌ Error en crearProducto: $e');
      String errorMessage = 'Error al crear el producto';

      if (e is PostgrestException) {
        print('❌ Código de error: ${e.code}');
        print('❌ Mensaje: ${e.message}');
        print('❌ Detalles: ${e.details}');

        // Mensajes más específicos según el tipo de error
        switch (e.code) {
          case '23505': // unique_violation
            errorMessage = 'Ya existe un producto con este nombre';
            break;
          case '23503': // foreign_key_violation
            errorMessage = 'La categoría o proveedor seleccionado no existe';
            break;
          case '23502': // not_null_violation
            errorMessage = 'Faltan datos requeridos';
            break;
          default:
            errorMessage = 'Error al crear el producto: ${e.message}';
        }
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': errorMessage,
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
  static Future<Map<String, dynamic>> verificarNombreProducto(String nombre) async {
    try {
      if (nombre.trim().isEmpty) {
        return {
          'success': true,
          'existe': false,
          'message': 'El nombre está vacío',
        };
      }

      print('🔍 Verificando nombre de producto: $nombre');
      final response = await _client
          .from('Productos')
          .select('id, nombre')
          .ilike('nombre', nombre.trim())
          .limit(1);

      final existe = (response as List).isNotEmpty;
      
      print('✅ Resultado verificación: ${existe ? "Existe" : "No existe"}');
      
      return {
        'success': true,
        'existe': existe,
        'message': existe ? 'Ya existe un producto con este nombre' : 'Nombre disponible',
      };
    } catch (e) {
      print('❌ Error en verificarNombreProducto: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al verificar el nombre del producto',
      };
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
  static Future<Map<String, dynamic>> crearCategoria(Categoria categoria) async {
    try {
      print('📝 Creando categoría: ${categoria.nombre}');
      
      final response = await _client
          .from('Categoria_producto')
          .insert({
            'nombre': categoria.nombre.trim(),
            'conCaducidad': categoria.conCaducidad,
          })
          .select()
          .single();

      print('✅ Categoría creada en Supabase: $response');

      return {
        'success': true,
        'data': Categoria.fromJson(response),
        'message': 'Categoría creada exitosamente',
      };
    } catch (e) {
      print('❌ Error en crearCategoria: $e');
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

  // Verificar estructura de la base de datos
  static Future<Map<String, dynamic>> verificarEstructuraDB() async {
    try {
      print('🔍 Verificando estructura de la base de datos...');
      
      // Verificar tabla Categoria_producto
      final categoriasResponse = await _client
          .from('Categoria_producto')
          .select('id, nombre, conCaducidad');
      print('✅ Tabla Categoria_producto accesible');
      print('📊 Categorías existentes en DB:');
      for (var categoria in categoriasResponse as List) {
        print('  - ID: ${categoria['id']}, Nombre: ${categoria['nombre']}');
      }

      // Verificar tabla Proveedores
      final proveedoresResponse = await _client
          .from('Proveedores')
          .select('id, nombre');
      print('✅ Tabla Proveedores accesible');
      print('📊 Proveedores existentes en DB:');
      for (var proveedor in proveedoresResponse as List) {
        print('  - ID: ${proveedor['id']}, Nombre: ${proveedor['nombre']}');
      }

      // Verificar tabla Productos
      final productosResponse = await _client
          .from('Productos')
          .select('id, nombre');
      print('✅ Tabla Productos accesible');
      print('📊 Productos existentes en DB:');
      for (var producto in productosResponse as List) {
        print('  - ID: ${producto['id']}, Nombre: ${producto['nombre']}');
      }

      return {
        'success': true,
        'message': 'Estructura de base de datos verificada',
        'categorias': categoriasResponse,
        'proveedores': proveedoresResponse,
        'productos': productosResponse,
      };
    } catch (e) {
      print('❌ Error verificando estructura: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error verificando estructura de la base de datos',
      };
    }
  }
}
