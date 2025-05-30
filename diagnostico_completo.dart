import 'package:flutter/material.dart';
import 'package:invmicho/services/supabase_setup.dart';
import 'package:invmicho/services/producto_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Iniciando diagnóstico completo...');

  try {
    // 1. Inicializar Supabase
    print('\n📡 Paso 1: Inicializando Supabase...');
    await SupabaseSetup.initialize();
    print('✅ Supabase inicializado correctamente');

    // 2. Probar conexión básica
    print('\n🔌 Paso 2: Probando conexión...');
    final connectionResult = await SupabaseSetup.testConnection();
    print('Resultado conexión: ${connectionResult}');

    // 3. Probar estructura de DB
    print('\n🏗️ Paso 3: Verificando estructura de BD...');
    final estructuraResult = await ProductoService.verificarEstructuraDB();
    print('Resultado estructura: ${estructuraResult}');

    // 4. Probar obtener categorías
    print('\n📋 Paso 4: Obteniendo categorías...');
    final categoriasResult = await ProductoService.obtenerCategorias();
    print('Resultado categorías: ${categoriasResult}');

    // 5. Probar obtener productos
    print('\n📦 Paso 5: Obteniendo productos...');
    final productosResult = await ProductoService.obtenerProductos();
    print('Resultado productos: ${productosResult}');

    print('\n🎯 Diagnóstico completado');
  } catch (e, stackTrace) {
    print('💥 Error en diagnóstico: $e');
    print('📍 StackTrace: $stackTrace');
  }
}
