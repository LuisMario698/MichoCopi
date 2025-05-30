import 'package:invmicho/services/producto_service.dart';
import 'package:invmicho/services/supabase_setup.dart';

// Script para probar ProductoService específicamente
Future<void> main() async {
  print('🔧 Iniciando prueba del ProductoService...');
  
  try {
    // Inicializar Supabase usando la configuración del proyecto
    await SupabaseSetup.initialize();
    print('✅ Supabase inicializado correctamente');

    print('\n📋 Probando obtenerCategorias()...');
    
    final categoriasResult = await ProductoService.obtenerCategorias();
    
    if (categoriasResult['success']) {
      final categorias = categoriasResult['data'];
      print('✅ Categorías obtenidas exitosamente: ${categorias.length} encontradas');
      
      if (categoriasResult.containsKey('isOffline') && categoriasResult['isOffline']) {
        print('⚠️ Usando datos de prueba (sin conexión)');
      }
      
      for (var categoria in categorias) {
        print('  - ID: ${categoria.id}, Nombre: ${categoria.nombre}, Con Caducidad: ${categoria.conCaducidad}');
      }
    } else {
      print('❌ Error obteniendo categorías: ${categoriasResult['message']}');
      if (categoriasResult.containsKey('error')) {
        print('   Detalles: ${categoriasResult['error']}');
      }
    }

    print('\n📦 Probando obtenerProductos()...');
    
    final productosResult = await ProductoService.obtenerProductos();
    
    if (productosResult['success']) {
      final productos = productosResult['data'];
      print('✅ Productos obtenidos exitosamente: ${productos.length} encontrados');
      
      for (var producto in productos) {
        print('  - ID: ${producto.id}, Nombre: ${producto.nombre}, Precio: \$${producto.precio}');
        print('    Categoría ID: ${producto.idCategoriaProducto}, Stock: ${producto.stock}');
      }
    } else {
      print('❌ Error obteniendo productos: ${productosResult['message']}');
      if (productosResult.containsKey('error')) {
        print('   Detalles: ${productosResult['error']}');
      }
    }

    print('\n🔍 Probando verificarEstructuraDB()...');
    
    final estructuraResult = await ProductoService.verificarEstructuraDB();
    
    if (estructuraResult['success']) {
      print('✅ Estructura de BD verificada correctamente');
    } else {
      print('❌ Error verificando estructura: ${estructuraResult['message']}');
      if (estructuraResult.containsKey('error')) {
        print('   Detalles: ${estructuraResult['error']}');
      }
    }

    print('\n🎯 Prueba del ProductoService completada');

  } catch (e) {
    print('💥 Error general en la prueba: $e');
    print('📍 Stack trace: ${StackTrace.current}');
  }
}
