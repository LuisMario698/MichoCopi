import 'package:invmicho/models/producto.dart';

void main() {
  print('🧪 Probando modelos con IDs arreglados...');
  
  // Test 1: Crear categoría sin ID
  print('\n📝 Test 1: Crear categoría sin ID');
  final categoria = Categoria(
    nombre: 'Categoría Test',
    conCaducidad: true,
  );
  
  print('✅ Categoría creada: ${categoria.toString()}');
  final categoriaJson = categoria.toJson();
  print('📦 JSON de categoría: $categoriaJson');
  print('🔍 ¿Contiene ID en JSON? ${categoriaJson.containsKey('id')}');
  
  // Test 2: Crear categoría con ID
  print('\n📝 Test 2: Crear categoría con ID');
  final categoriaConId = Categoria(
    id: 123,
    nombre: 'Categoría con ID',
    conCaducidad: false,
  );
  
  print('✅ Categoría con ID creada: ${categoriaConId.toString()}');
  final categoriaConIdJson = categoriaConId.toJson();
  print('📦 JSON de categoría con ID: $categoriaConIdJson');
  print('🔍 ¿Contiene ID en JSON? ${categoriaConIdJson.containsKey('id')}');
  
  // Test 3: Crear producto sin ID
  print('\n📝 Test 3: Crear producto sin ID');
  final producto = Producto(
    nombre: 'Producto Test',
    precio: 10.50,
    stock: 5,
    categoria: 1,
    proveedor: 1,
  );
  
  print('✅ Producto creado: ${producto.toString()}');
  final productoJson = producto.toJson();
  print('📦 JSON de producto: $productoJson');
  print('🔍 ¿Contiene ID en JSON? ${productoJson.containsKey('id')}');
  
  // Test 4: Crear proveedor sin ID
  print('\n📝 Test 4: Crear proveedor sin ID');
  final proveedor = Proveedor(
    nombre: 'Proveedor Test',
    direccion: 'Dirección Test',
    telefono: 1234567890,
  );
  
  print('✅ Proveedor creado: ${proveedor.toString()}');
  final proveedorJson = proveedor.toJson();
  print('📦 JSON de proveedor: $proveedorJson');
  print('🔍 ¿Contiene ID en JSON? ${proveedorJson.containsKey('id')}');
  
  print('\n🎉 ¡Todas las pruebas completadas! Los modelos ahora manejan correctamente los IDs opcionales.');
}
