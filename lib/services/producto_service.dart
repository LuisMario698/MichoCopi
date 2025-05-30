import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';
import '../models/categoria_producto.dart';

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
        return {'success': false, 'message': 'El precio debe ser mayor a 0'};
      }

      print('📝 Creando producto: ${producto.nombre}');

      // Preparar datos del producto para insertar
      final productoData = producto.toJson();

      // Crear el producto
      final response =
          await _client
              .from('Productos')
              .insert(productoData)
              .select()
              .single();

      final productoCreado = Producto.fromJson(response);

      print('✅ Producto creado exitosamente en Supabase');

      return {
        'success': true,
        'data': productoCreado,
        'message': 'Producto creado exitosamente',
      };
    } catch (e) {
      print('❌ Error en crearProducto: $e');
      String errorMessage = 'Error al crear el producto';

      if (e is PostgrestException) {
        print('❌ Código de error: ${e.code}');
        print('❌ Mensaje: ${e.message}');
        print('❌ Detalles: ${e.details}');

        switch (e.code) {
          case '23505': // unique_violation
            errorMessage = 'Ya existe un producto con este nombre';
            break;
          case '23503': // foreign_key_violation
            String detail = e.details?.toString() ?? '';
            if (detail.contains('id_Categoria_producto')) {
              errorMessage = 'La categoría seleccionada no existe';
            } else if (detail.contains('id_Receta')) {
              errorMessage = 'La receta especificada no existe';
            } else {
              errorMessage = 'Error de referencia en la base de datos';
            }
            break;
          case '23502': // not_null_violation
            errorMessage = 'Faltan datos requeridos';
            break;
          default:
            errorMessage = 'Error al crear el producto: ${e.message}';
        }
      }

      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    }
  }
  // Obtener todos los productos
  static Future<Map<String, dynamic>> obtenerProductos() async {
    try {
      print('🔍 Iniciando obtenerProductos...');
      
      final response = await _client
          .from('Productos')
          .select()
          .order('id', ascending: false)
          .timeout(const Duration(seconds: 10));

      print('📦 Respuesta raw de Productos: $response');
      print('📦 Tipo de respuesta: ${response.runtimeType}');
      print('📦 Longitud de respuesta: ${(response as List).length}');

      final productos = (response as List)
          .map((item) {
            print('🔍 Procesando producto: $item');
            try {
              return Producto.fromJson(item);
            } catch (e) {
              print('❌ Error procesando producto $item: $e');
              rethrow;
            }
          })
          .toList();

      print('✅ Productos procesados exitosamente: ${productos.length}');

      return {
        'success': true,
        'data': productos,
        'message': 'Productos obtenidos exitosamente',
      };
    } catch (e, stackTrace) {
      print('❌ Error completo en obtenerProductos: $e');
      print('📍 StackTrace: $stackTrace');
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al obtener los productos: ${e.toString()}',
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
      final productoData = producto.toJson();
      // Asegurar que usamos el ID correcto
      productoData['id'] = id;

      final response =
          await _client
              .from('Productos')
              .update(productoData)
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
        'message':
            existe
                ? 'Ya existe un producto con este nombre'
                : 'Nombre disponible',
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
  static Future<Map<String, dynamic>> crearCategoria(
    CategoriaProducto categoria,
  ) async {
    try {
      print('📝 Creando categoría: ${categoria.nombre}');

      final response =
          await _client
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
        'data': CategoriaProducto.fromJson(response),
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
  // Obtener todas las categorías
  static Future<Map<String, dynamic>> obtenerCategorias() async {
    try {
      print('🔍 Iniciando obtenerCategorias...');
      
      final response = await _client
          .from('Categoria_producto')
          .select()
          .order('nombre', ascending: true)
          .timeout(const Duration(seconds: 10));

      print('📦 Respuesta raw de Supabase: $response');
      print('📦 Tipo de respuesta: ${response.runtimeType}');
      print('📦 Longitud de respuesta: ${(response as List).length}');

      final categorias = (response as List)
          .map((item) {
            print('🔍 Procesando item: $item');
            print('🔍 Tipo de item: ${item.runtimeType}');
            try {
              return CategoriaProducto.fromJson(item);
            } catch (e) {
              print('❌ Error procesando item $item: $e');
              rethrow;
            }
          })
          .toList();

      print('✅ Categorías procesadas exitosamente: ${categorias.length}');

      return {
        'success': true,
        'data': categorias,
        'message': 'Categorías obtenidas exitosamente',
      };
    } catch (e, stackTrace) {
      print('❌ Error completo en obtenerCategorias: $e');
      print('📍 StackTrace: $stackTrace');

      // Determinar el tipo de error y mostrar mensaje apropiado
      String errorMessage = 'Error de conexión';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Operation not permitted')) {
        errorMessage =
            'Sin conexión a la base de datos. Usando datos de prueba.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Tiempo de espera agotado. Usando datos de prueba.';
      } else if (e.toString().contains('PostgrestException')) {
        errorMessage = 'Error en la base de datos: ${e.toString()}';
      } else {
        errorMessage = 'Error procesando datos: ${e.toString()}';
      }

      // Retornar datos de prueba en caso de error de conexión
      final categoriasPrueba = [
        CategoriaProducto(id: 1, nombre: 'Electrónicos', conCaducidad: false),
        CategoriaProducto(id: 2, nombre: 'Alimentos', conCaducidad: true),
        CategoriaProducto(id: 3, nombre: 'Medicamentos', conCaducidad: true),
        CategoriaProducto(id: 4, nombre: 'Ropa', conCaducidad: false),
        CategoriaProducto(id: 5, nombre: 'Bebidas', conCaducidad: true),
        CategoriaProducto(id: 6, nombre: 'Limpieza', conCaducidad: false),
        CategoriaProducto(id: 7, nombre: 'Cosméticos', conCaducidad: true),
      ];

      return {
        'success': true,
        'data': categoriasPrueba,
        'message': errorMessage,
        'isOffline': true,
        'error': e.toString(),
      };
    }
  }// El método obtenerProveedores se ha movido a ProveedorService

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

  // Obtener materias primas de una receta
  static Future<List<String>> obtenerMateriasPrimasDeReceta(
    int? idReceta,
  ) async {
    try {
      if (idReceta == null) {
        return [];
      }

      // Obtener la receta
      final recetaResponse =
          await _client
              .from('Receta')
              .select('ids_Mps')
              .eq('id', idReceta)
              .single();

      final List<dynamic> idsMps = recetaResponse['ids_Mps'] ?? [];

      if (idsMps.isEmpty) {
        return [];
      }

      // Obtener los nombres de las materias primas
      final materiasResponse = await _client
          .from('Materia_prima')
          .select('nombre')
          .inFilter('id', idsMps);

      return (materiasResponse as List)
          .map((mp) => mp['nombre'] as String)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo materias primas de receta: $e');
      return [];
    }
  }
}
