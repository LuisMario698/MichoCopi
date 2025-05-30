import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('🔧 Prueba básica de Supabase...');
  
  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: 'https://dwruaswwduegczsgelia.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3cnVhc3d3ZHVlZ2N6c2dlbGlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY1NTUxMTMsImV4cCI6MjA2MjEzMTExM30.OtewBCBvXSIHHJZth4CZxHZ92PF8FBfg0IEB0PKXg4c',
    );

    final client = Supabase.instance.client;
    print('✅ Cliente Supabase inicializado');

    // Probar consulta simple en tabla Categoria_producto
    print('\n🧪 Probando tabla Categoria_producto...');
    final categorias = await client
        .from('Categoria_producto')
        .select('*');
    
    print('📊 Categorías encontradas: ${categorias.length}');
    for (var cat in categorias) {
      print('  - ${cat}');
    }

    // Probar consulta simple en tabla Productos
    print('\n🧪 Probando tabla Productos...');
    final productos = await client
        .from('Productos')
        .select('*');
    
    print('📊 Productos encontrados: ${productos.length}');
    for (var prod in productos) {
      print('  - ${prod}');
    }

    print('\n✅ Prueba completada exitosamente');

  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('📍 StackTrace: $stackTrace');
  }
}
