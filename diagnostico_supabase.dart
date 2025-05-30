import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('🔧 Iniciando diagnóstico de conexión...');
  
  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: 'https://dwruaswwduegczsgelia.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3cnVhc3d3ZHVlZ2N6c2dlbGlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY1NTUxMTMsImV4cCI6MjA2MjEzMTExM30.OtewBCBvXSIHHJZth4CZxHZ92PF8FBfg0IEB0PKXg4c',
    );

    final client = Supabase.instance.client;
    print('✅ Supabase inicializado correctamente');

    // Test 1: Probar tabla Categoria_producto
    print('\n🧪 Test 1: Tabla Categoria_producto');
    try {
      final result = await client
          .from('Categoria_producto')
          .select('*')
          .timeout(const Duration(seconds: 10));
      
      print('✅ Categorías encontradas: ${result.length}');
      if (result.isNotEmpty) {
        print('   Primera categoría: ${result[0]}');
      }
    } on TimeoutException {
      print('❌ Timeout al consultar Categoria_producto');
    } catch (e) {
      print('❌ Error en Categoria_producto: $e');
    }

    // Test 2: Probar tabla Productos
    print('\n🧪 Test 2: Tabla Productos');
    try {
      final result = await client
          .from('Productos')
          .select('*')
          .timeout(const Duration(seconds: 10));
      
      print('✅ Productos encontrados: ${result.length}');
      if (result.isNotEmpty) {
        print('   Primer producto: ${result[0]}');
      }
    } on TimeoutException {
      print('❌ Timeout al consultar Productos');
    } catch (e) {
      print('❌ Error en Productos: $e');
    }

    // Test 3: Verificar estructura específica de campos
    print('\n🧪 Test 3: Verificar estructura de campos');
    try {
      final categoriaTest = await client
          .from('Categoria_producto')
          .select('id, nombre, conCaducidad')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      
      if (categoriaTest.isNotEmpty) {
        final cat = categoriaTest[0];
        print('✅ Estructura Categoria_producto:');
        print('   id: ${cat['id']} (${cat['id'].runtimeType})');
        print('   nombre: ${cat['nombre']} (${cat['nombre'].runtimeType})');
        print('   conCaducidad: ${cat['conCaducidad']} (${cat['conCaducidad'].runtimeType})');
      }
    } catch (e) {
      print('❌ Error verificando estructura: $e');
    }

    // Test 4: Insertar una categoría de prueba
    print('\n🧪 Test 4: Insertar categoría de prueba');
    try {
      final insertResult = await client
          .from('Categoria_producto')
          .insert({
            'nombre': 'Categoría Test ${DateTime.now().millisecondsSinceEpoch}',
            'conCaducidad': false,
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      
      print('✅ Categoría insertada: ${insertResult}');
      
      // Eliminar la categoría de prueba
      await client
          .from('Categoria_producto')
          .delete()
          .eq('id', insertResult['id']);
      
      print('✅ Categoría de prueba eliminada');
    } catch (e) {
      print('❌ Error insertando categoría de prueba: $e');
    }

    print('\n🎯 Diagnóstico completado');

  } catch (e) {
    print('💥 Error general: $e');
    print('📍 Tipo de error: ${e.runtimeType}');
  }
}
