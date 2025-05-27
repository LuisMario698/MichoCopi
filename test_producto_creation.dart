import 'package:flutter/material.dart';
import 'lib/models/producto.dart';
import 'lib/services/producto_service.dart';

// Test simple para verificar la creación de productos
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Iniciando test de creación de producto...');
  
  // Crear un producto de prueba
  final productoTest = Producto(
    nombre: 'Producto Test ${DateTime.now().millisecondsSinceEpoch}',
    precio: 99.99,
    stock: 50,
    categoria: 1, // ID de categoría
    proveedor: 1, // ID de proveedor
    caducidad: DateTime.now().add(const Duration(days: 30)),
  );
  
  print('📝 Producto a crear: ${productoTest.toString()}');
  print('📝 JSON del producto: ${productoTest.toJson()}');
  
  // Verificar que los IDs están presentes
  print('🔍 Verificando IDs:');
  print('  - ID Categoría: ${productoTest.categoria} (tipo: ${productoTest.categoria.runtimeType})');
  print('  - ID Proveedor: ${productoTest.proveedor} (tipo: ${productoTest.proveedor.runtimeType})');
  
  // Verificar el JSON
  final json = productoTest.toJson();
  print('🔍 Verificando JSON:');
  json.forEach((key, value) {
    print('  - $key: $value (${value.runtimeType})');
  });
  
  // Intentar crear el producto
  try {
    print('🚀 Intentando crear producto...');
    final result = await ProductoService.crearProducto(productoTest);
    
    print('📋 Resultado:');
    print('  - Success: ${result['success']}');
    print('  - Message: ${result['message']}');
    if (result['error'] != null) {
      print('  - Error: ${result['error']}');
    }
    if (result['data'] != null) {
      print('  - Data: ${result['data']}');
    }
    
    if (result['success']) {
      print('✅ ¡Producto creado exitosamente!');
    } else {
      print('❌ Error al crear producto: ${result['message']}');
    }
  } catch (e) {
    print('💥 Excepción durante la creación: $e');
  }
  
  print('🏁 Test completado.');
}
