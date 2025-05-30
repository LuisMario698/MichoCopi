import 'package:flutter/foundation.dart';
import 'lib/services/supabase_setup.dart';
import 'lib/services/tipo_cambio_service.dart';

Future<void> main() async {
  try {
    print('🚀 Iniciando prueba del sistema de tipo de cambio...');

    // Inicializar Supabase
    await SupabaseSetup.initialize();
    print('✅ Supabase inicializado correctamente');

    // Probar obtener tipo de cambio
    print('\n📈 Obteniendo tipo de cambio actual...');
    final resultadoObtener = await TipoCambioService.obtenerTipoCambio();

    if (resultadoObtener['success']) {
      print(
        '✅ Tipo de cambio obtenido: \$${resultadoObtener['data']} MXN por USD',
      );
    } else {
      print(
        '❌ Error al obtener tipo de cambio: ${resultadoObtener['message']}',
      );
      return;
    }

    // Probar actualizar tipo de cambio
    print('\n📝 Actualizando tipo de cambio a 18.25...');
    final resultadoActualizar = await TipoCambioService.actualizarTipoCambio(
      18.25,
    );

    if (resultadoActualizar['success']) {
      print('✅ ${resultadoActualizar['message']}');
    } else {
      print('❌ Error al actualizar: ${resultadoActualizar['message']}');
      return;
    }

    // Verificar que se actualizó correctamente
    print('\n🔍 Verificando actualización...');
    final resultadoVerificar = await TipoCambioService.obtenerTipoCambio();

    if (resultadoVerificar['success']) {
      print(
        '✅ Tipo de cambio actualizado: \$${resultadoVerificar['data']} MXN por USD',
      );
    } else {
      print('❌ Error al verificar: ${resultadoVerificar['message']}');
    }

    // Restaurar valor original
    print('\n🔄 Restaurando valor original (17.5)...');
    final resultadoRestaurar = await TipoCambioService.actualizarTipoCambio(
      17.5,
    );

    if (resultadoRestaurar['success']) {
      print('✅ Valor restaurado correctamente');
    } else {
      print('❌ Error al restaurar: ${resultadoRestaurar['message']}');
    }

    print('\n🎉 Prueba del sistema de tipo de cambio completada exitosamente!');
  } catch (e) {
    print('❌ Error durante la prueba: $e');
  }
}
