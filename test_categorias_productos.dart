import 'package:supabase_flutter/supabase_flutter.dart';

// Script para probar la carga de categorías y productos
Future<void> main() async {
  print('🔧 Iniciando prueba de categorías y productos...');
  
  try {
    // Configurar Supabase (usa tus credenciales reales)
    await Supabase.initialize(
      url: 'https://tusupabaseurl.supabase.co',
      anonKey: 'tu_anon_key_aqui',
    );

    final supabase = Supabase.instance.client;

    print('\n📋 Probando tabla Categoria_producto...');
    
    // Probar categorías
    try {
      final categoriasResponse = await supabase
          .from('Categoria_producto')
          .select()
          .order('nombre', ascending: true);
      
      print('✅ Categorías cargadas exitosamente: ${categoriasResponse.length} encontradas');
      
      for (var categoria in categoriasResponse) {
        print('  - ID: ${categoria['id']}, Nombre: ${categoria['nombre']}, Con Caducidad: ${categoria['conCaducidad']}');
      }
      
    } catch (e) {
      print('❌ Error cargando categorías: $e');
    }

    print('\n📦 Probando tabla Productos...');
    
    // Probar productos
    try {
      final productosResponse = await supabase
          .from('Productos')
          .select()
          .order('id', ascending: false);
      
      print('✅ Productos cargados exitosamente: ${productosResponse.length} encontrados');
      
      for (var producto in productosResponse) {
        print('  - ID: ${producto['id']}, Nombre: ${producto['nombre']}, Precio: \$${producto['precio']}');
      }
      
    } catch (e) {
      print('❌ Error cargando productos: $e');
    }

    print('\n🔍 Verificando estructura de tablas...');
    
    // Verificar estructura de Categoria_producto
    try {
      final categoriaTest = await supabase
          .from('Categoria_producto')
          .select('id, nombre, conCaducidad')
          .limit(1);
      print('✅ Estructura de Categoria_producto: OK');
    } catch (e) {
      print('❌ Error en estructura de Categoria_producto: $e');
    }

    // Verificar estructura de Productos
    try {
      final productoTest = await supabase
          .from('Productos')
          .select('id, nombre, precio, id_Categoria_producto, id_Usuario, id_Receta, tamaño, stock, fecha_caducidad')
          .limit(1);
      print('✅ Estructura de Productos: OK');
    } catch (e) {
      print('❌ Error en estructura de Productos: $e');
    }

    print('\n🎯 Prueba completada');

  } catch (e) {
    print('💥 Error general: $e');
  }
}
