import 'package:supabase_flutter/supabase_flutter.dart';

class TipoCambioService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'Configuracion';

  // Obtener el tipo de cambio actual
  static Future<Map<String, dynamic>> obtenerTipoCambio() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('clave', 'tipo_cambio_dolares')
          .maybeSingle();

      if (response != null) {
        final double tipoCambio = double.tryParse(response['valor'] ?? '0') ?? 0.0;
        return {
          'success': true,
          'data': tipoCambio,
        };
      } else {
        // Si no existe el tipo de cambio, crear uno por defecto
        await _supabase.from(_tableName).upsert({
          'clave': 'tipo_cambio_dolares',
          'valor': '17.50', // Valor por defecto
          'descripcion': 'Tipo de cambio de pesos a dólares'
        });
        
        return {
          'success': true,
          'data': 17.50, // Valor por defecto
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener tipo de cambio: $e',
        'data': 17.50, // Valor por defecto en caso de error
      };
    }
  }

  // Actualizar el tipo de cambio
  static Future<Map<String, dynamic>> actualizarTipoCambio(double nuevoTipo) async {
    try {
      await _supabase.from(_tableName).upsert({
        'clave': 'tipo_cambio_dolares',
        'valor': nuevoTipo.toString(),
        'descripcion': 'Tipo de cambio de pesos a dólares'
      });
      
      return {
        'success': true,
        'message': 'Tipo de cambio actualizado correctamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar tipo de cambio: $e',
      };
    }
  }
}
