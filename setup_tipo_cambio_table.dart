import 'package:supabase_flutter/supabase_flutter.dart';

// Script para configurar la tabla tipo_cambio con el valor por defecto
Future<void> setupTipoCambioTable() async {
  try {
    // Configurar Supabase (usar tus credenciales)
    await Supabase.initialize(
      url: 'TU_SUPABASE_URL',
      anonKey: 'TU_SUPABASE_ANON_KEY',
    );

    final supabase = Supabase.instance.client;

    print('🔄 Configurando tabla tipo_cambio...');

    // Verificar si ya existe el registro
    final existing = await supabase
        .from('tipo_cambio')
        .select()
        .eq('id', 1)
        .maybeSingle();

    if (existing == null) {
      // Insertar el valor por defecto
      await supabase.from('tipo_cambio').insert({
        'id': 1,
        'cambio': 17.5,
      });
      print('✅ Tipo de cambio por defecto insertado: 17.5');
    } else {
      print('ℹ️ Ya existe un tipo de cambio: ${existing['cambio']}');
    }

    print('✅ Configuración de tabla tipo_cambio completada');

  } catch (e) {
    print('❌ Error al configurar tabla tipo_cambio: $e');
  }
}

void main() async {
  await setupTipoCambioTable();
}
