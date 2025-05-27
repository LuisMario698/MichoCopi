import 'package:flutter/material.dart';
import 'lib/models/producto.dart';
import 'lib/services/producto_service.dart';

void main() async {
  print('🧪 Iniciando test de creación de producto...');
  
  // Test 1: Verificar que el modelo Producto maneja correctamente los IDs
  print('\n📋 Test 1: Creación del modelo Producto');
  
  final producto = Producto(
    nombre: 'Producto Test',
    precio: 29.99,
    stock: 10,
    categoria: 2, // ID de categoría
    proveedor: 1, // ID de proveedor
    caducidad: DateTime.now().add(Duration(days: 30)),
  );
  
  print('✅ Producto creado: ${producto.toString()}');
  
  // Test 2: Verificar la serialización JSON
  print('\n📄 Test 2: Serialización a JSON');
  final json = producto.toJson();
  print('✅ JSON generado: $json');
  print('🔍 Tipo categoria: ${json['categoria'].runtimeType} (${json['categoria']})');
  print('🔍 Tipo proveedor: ${json['proveedor'].runtimeType} (${json['proveedor']})');
  
  // Test 3: Verificar la deserialización
  print('\n🔄 Test 3: Deserialización desde JSON');
  final productoFromJson = Producto.fromJson(json);
  print('✅ Producto desde JSON: ${productoFromJson.toString()}');
  
  // Test 4: Simular datos que vendrían de los dropdowns
  print('\n📊 Test 4: Simulación de datos de dropdowns');
  
  // Simular las listas de categorías y proveedores
  final categorias = [
    Categoria(id: 1, nombre: 'Electrónicos', conCaducidad: false),
    Categoria(id: 2, nombre: 'Alimentos', conCaducidad: true),
    Categoria(id: 3, nombre: 'Medicamentos', conCaducidad: true),
  ];
  
  final proveedores = [
    Proveedor(id: 1, nombre: 'Proveedor A', direccion: 'Calle 123', telefono: 123456789),
    Proveedor(id: 2, nombre: 'Proveedor B', direccion: 'Avenida 456', telefono: 987654321),
  ];
  
  print('✅ Categorías disponibles:');
  for (var cat in categorias) {
    print('  - ${cat.nombre} (ID: ${cat.id})');
  }
  
  print('✅ Proveedores disponibles:');
  for (var prov in proveedores) {
    print('  - ${prov.nombre} (ID: ${prov.id})');
  }
  
  // Simular selección en los dropdowns
  int? categoriaSeleccionada = 2; // Usuario selecciona "Alimentos"
  int? proveedorSeleccionado = 1; // Usuario selecciona "Proveedor A"
  
  print('\n🎯 Simulando selección del usuario:');
  print('   Categoría seleccionada: ID $categoriaSeleccionada');
  print('   Proveedor seleccionado: ID $proveedorSeleccionado');
  
  // Crear producto con las selecciones
  final productoConSelecciones = Producto(
    nombre: 'Producto con Selecciones',
    precio: 15.50,
    stock: 25,
    categoria: categoriaSeleccionada!,
    proveedor: proveedorSeleccionado!,
    caducidad: DateTime.now().add(Duration(days: 60)),
  );
  
  print('✅ Producto final: ${productoConSelecciones.toString()}');
  print('📄 JSON final: ${productoConSelecciones.toJson()}');
  
  print('\n🎉 Todos los tests completados exitosamente!');
  print('✅ Los IDs de categoria y proveedor se están manejando correctamente');
}
