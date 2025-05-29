import 'package:flutter/material.dart';
import 'package:invmicho/services/supabase_setup.dart';
import 'package:invmicho/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== DIAGNÓSTICO DE LOGIN ===');
  
  // Inicializar Supabase
  print('🔧 Inicializando Supabase...');
  try {
    await SupabaseSetup.initialize();
    print('✅ Supabase inicializado correctamente');
  } catch (e) {
    print('❌ Error al inicializar Supabase: $e');
    return;
  }
  
  // Probar conexión básica
  print('\n🔍 Probando conexión básica...');
  try {
    final connectionTest = await SupabaseSetup.testConnection();
    print('📊 Resultado de conexión: $connectionTest');
  } catch (e) {
    print('❌ Error en test de conexión: $e');
  }
  
  // Verificar si la tabla Usuario existe
  print('\n🔍 Verificando tabla Usuario...');
  try {
    final tablaExiste = await AuthService.verificarTablaUsuarios();
    print('📋 ¿Tabla Usuario existe?: $tablaExiste');
    
    if (!tablaExiste) {
      print('⚠️  La tabla Usuario no existe. Esto puede ser el problema.');
      print('💡 Posibles soluciones:');
      print('   1. Verificar en Supabase que la tabla se llame "Usuario" (con U mayúscula)');
      print('   2. O cambiar el código para usar el nombre correcto de la tabla');
      return;
    }
  } catch (e) {
    print('❌ Error al verificar tabla Usuario: $e');
  }
  
  // Intentar obtener lista de usuarios (para ver qué hay en la tabla)
  print('\n📋 Intentando obtener lista de usuarios...');
  try {
    final listaUsuarios = await AuthService.obtenerTodosLosUsuarios();
    print('👥 Resultado obtener usuarios: $listaUsuarios');
    
    if (listaUsuarios['success']) {
      final usuarios = listaUsuarios['data'] as List;
      print('🔢 Cantidad de usuarios encontrados: ${usuarios.length}');
      
      for (var usuario in usuarios) {
        print('👤 Usuario: ${usuario.nombre} (ID: ${usuario.id})');
      }
      
      // Buscar específicamente el usuario "Admin"
      final adminExiste = usuarios.any((u) => u.nombre == 'Admin');
      print('🔍 ¿Usuario "Admin" existe?: $adminExiste');
      
      if (!adminExiste) {
        print('⚠️  El usuario "Admin" no existe en la base de datos.');
        print('💡 Necesitas crear el usuario "Admin" con contraseña "1234" en Supabase.');
      }
    }
  } catch (e) {
    print('❌ Error al obtener usuarios: $e');
  }
  
  // Intentar login con credenciales de prueba
  print('\n🔑 Intentando login con Admin/1234...');
  try {
    final result = await AuthService.iniciarSesion(
      nombre: 'Admin',
      password: '1234',
    );
    
    print('📝 Resultado completo del login: $result');
    
    if (result['success']) {
      print('🎉 ¡Login exitoso!');
      print('👤 Usuario logueado: ${result['data']?.nombre}');
      
      // Cerrar sesión para limpiar
      await AuthService.cerrarSesion();
      print('🚪 Sesión cerrada');
    } else {
      print('❌ Login falló: ${result['message']}');
      print('💡 Esto indica que el usuario Admin no existe o la contraseña es incorrecta.');
    }
  } catch (e) {
    print('💥 Error crítico durante el login: $e');
    print('📊 Tipo de error: ${e.runtimeType}');
    
    // Si es un error de Postgres, extraer más información
    if (e.toString().contains('42P01')) {
      print('🔍 Error 42P01 detectado: La tabla no existe');
      print('💡 Solución: Verificar el nombre de la tabla en Supabase');
    }
  }
  
  print('\n🏁 Diagnóstico completado');
}
