import 'package:flutter/material.dart';
import 'lib/services/supabase_setup.dart';
import 'lib/services/auth_service.dart';
import 'lib/services/tipo_usuario_service.dart';
import 'lib/models/usuario.dart';
import 'lib/models/tipo_usuario.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 INICIANDO PRUEBAS DEL SISTEMA DE AUTENTICACIÓN');
  print('=' * 60);
  
  try {
    // Paso 1: Inicializar Supabase
    print('\n📡 PASO 1: Inicializando Supabase...');
    await SupabaseSetup.initialize();
    print('✅ Supabase inicializado correctamente');
    
    // Paso 2: Probar conexión
    print('\n🔌 PASO 2: Probando conexión...');
    final connectionTest = await SupabaseSetup.testConnection();
    print('Resultado conexión: ${connectionTest['success']}');
    print('Mensaje: ${connectionTest['message']}');
    
    // Paso 3: Probar tipos de usuario
    print('\n👥 PASO 3: Probando tipos de usuario...');
    
    // Inicializar tipos básicos
    await TipoUsuarioService.inicializarTiposBasicos();
    print('✅ Tipos básicos inicializados');
    
    // Obtener tipos
    final tiposResult = await TipoUsuarioService.obtenerTiposUsuario();
    if (tiposResult['success']) {
      final tipos = tiposResult['data'] as List<TipoUsuario>;
      print('✅ Tipos obtenidos: ${tipos.length}');
      for (var tipo in tipos) {
        print('  - ${tipo.nombre}: ${tipo.descripcion}');
      }
    } else {
      print('❌ Error obteniendo tipos: ${tiposResult['message']}');
    }
    
    // Paso 4: Probar registro de usuario
    print('\n📝 PASO 4: Probando registro de usuario...');
    
    final tipoUsuario = await TipoUsuarioService.obtenerTiposUsuario();
    if (tipoUsuario['success']) {
      final tipos = tipoUsuario['data'] as List<TipoUsuario>;
      final tipoTest = tipos.first;
      
      final registroResult = await AuthService.registrarUsuario(
        nombre: 'testuser_${DateTime.now().millisecondsSinceEpoch}',
        password: 'password123',
        tipo: tipoTest.id!,
      );
      
      print('Resultado registro: ${registroResult['success']}');
      print('Mensaje: ${registroResult['message']}');
      
      if (registroResult['success']) {
        print('✅ Usuario registrado exitosamente');
      } else {
        print('❌ Error en registro: ${registroResult['message']}');
      }
    }
    
    // Paso 5: Probar login
    print('\n🔐 PASO 5: Probando login...');
    
    // Primero intentar con el admin por defecto
    final loginResult = await AuthService.iniciarSesion(
      nombre: 'admin',
      password: 'admin123',
    );
    
    print('Resultado login: ${loginResult['success']}');
    print('Mensaje: ${loginResult['message']}');
    
    if (loginResult['success']) {
      print('✅ Login exitoso');
      final usuario = loginResult['data'] as Usuario;
      print('Usuario logueado: ${usuario.nombre}');
      print('Tipo: ${usuario.tipoUsuario?.nombre ?? "N/A"}');
    } else {
      print('❌ Error en login: ${loginResult['message']}');
    }
    
    // Paso 6: Probar logout
    print('\n🚪 PASO 6: Probando logout...');
    await AuthService.cerrarSesion();
    print('✅ Logout exitoso');
    
    print('\n🎉 TODAS LAS PRUEBAS COMPLETADAS');
    print('=' * 60);
    
  } catch (e) {
    print('❌ ERROR CRÍTICO EN LAS PRUEBAS: $e');
    print('💡 Esto puede indicar un problema con la configuración o conexión');
  }
}
