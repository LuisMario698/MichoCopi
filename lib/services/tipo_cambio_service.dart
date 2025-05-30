import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tipo_cambio.dart';

class TipoCambioService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'tipo_cambio';

  // Obtener el tipo de cambio actual
  static Future<Map<String, dynamic>> obtenerTipoCambio() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (response != null) {
        final tipoCambio = TipoCambio.fromJson(response);
        return {'success': true, 'data': tipoCambio.cambio};
      } else {
        // Si no existe el tipo de cambio, crear uno por defecto
        await _supabase.from(_tableName).insert({
          'id': 1,
          'cambio': 17.50, // Valor por defecto
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
  static Future<Map<String, dynamic>> actualizarTipoCambio(
    double nuevoTipo,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update({'cambio': nuevoTipo})
          .eq('id', 1)
          .select()
          .maybeSingle();

      if (response != null) {
        return {
          'success': true,
          'message': 'Tipo de cambio actualizado correctamente',
          'data': nuevoTipo,
        };
      } else {
        // Si no existe, lo creamos
        await _supabase.from(_tableName).insert({
          'id': 1,
          'cambio': nuevoTipo,
        });

        return {
          'success': true,
          'message': 'Tipo de cambio creado correctamente',
          'data': nuevoTipo,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar tipo de cambio: $e',
      };
    }
  }

  // Obtener el objeto TipoCambio completo
  static Future<Map<String, dynamic>> obtenerTipoCambioCompleto() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (response != null) {
        final tipoCambio = TipoCambio.fromJson(response);
        return {'success': true, 'data': tipoCambio};
      } else {
        // Si no existe el tipo de cambio, crear uno por defecto
        final defaultTipoCambio = TipoCambio(id: 1, cambio: 17.50);
        await _supabase.from(_tableName).insert(defaultTipoCambio.toJson());

        return {
          'success': true,
          'data': defaultTipoCambio,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener tipo de cambio: $e',
        'data': TipoCambio(id: 1, cambio: 17.50), // Valor por defecto
      };
    }
  }
}
