// Script para verificar y crear la tabla usuarios en Supabase
import 'package:flutter/widgets.dart';
import 'lib/services/supabase_setup.dart';
import 'lib/services/auth_service.dart';

void main() async {
  print('🚀 Configurando tabla de usuarios en Supabase...');
  
  try {
    // Inicializar Supabase
    await SupabaseSetup.initialize();
    print('✅ Supabase inicializado correctamente');
    
    // Verificar la tabla usuarios
    bool tablaExiste = await AuthService.verificarTablaUsuarios();
    
    if (tablaExiste) {
      print('✅ La tabla "usuarios" ya existe en Supabase');
    } else {
      print('❌ La tabla "usuarios" no existe');
      print('📝 Necesitas crear la tabla "usuarios" en Supabase con la siguiente estructura:');
      print('''
CREATE TABLE usuarios (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  usuario VARCHAR(50) UNIQUE NOT NULL,
  contrasena VARCHAR(255) NOT NULL,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índice único para el nombre de usuario
CREATE UNIQUE INDEX idx_usuarios_usuario ON usuarios(usuario);

-- Habilitar RLS (Row Level Security)
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

-- Crear política para permitir operaciones básicas
CREATE POLICY "Permitir todas las operaciones en usuarios" ON usuarios
  FOR ALL USING (true);
      ''');
    }
    
    print('🔍 Verificación completada');
    
  } catch (e) {
    print('❌ Error durante la configuración: $e');
  }
}
