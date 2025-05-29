import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/compras.dart';

class ComprasService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'compras';

  // Obtener todas las compras
  Future<List<Compras>> obtenerTodas() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => Compras.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener compras: $e');
    }
  }

  // Obtener compra por ID
  Future<Compras?> obtenerPorId(int id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Compras.fromJson(response) : null;
    } catch (e) {
      throw Exception('Error al obtener compra: $e');
    }
  }

  // Obtener compras por proveedor
  Future<List<Compras>> obtenerPorProveedor(int idProveedor) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id_proveedor', idProveedor)
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => Compras.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener compras por proveedor: $e');
    }
  }
  // Obtener compras por materia prima
  Future<List<Compras>> obtenerPorMateriaPrima(int idMateriaPrima) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id_mp', idMateriaPrima)
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => Compras.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener compras por materia prima: $e');
    }
  }

  // Obtener compras por rango de fechas
  Future<List<Compras>> obtenerPorRangoFechas(DateTime fechaInicio, DateTime fechaFin) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .gte('fecha', fechaInicio.toIso8601String())
          .lte('fecha', fechaFin.toIso8601String())
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => Compras.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener compras por rango de fechas: $e');
    }
  }
  // Crear nueva compra
  Future<Compras> crear(Compras compra) async {
    try {
      // Validar antes de crear
      final errores = compra.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }

      final response = await _supabase
          .from(_tableName)
          .insert(compra.toJson())
          .select()
          .single();

      final compraCreada = Compras.fromJson(response);
      return compraCreada;
    } catch (e) {
      throw Exception('Error al crear compra: $e');
    }
  }

  // Actualizar compra
  Future<Compras> actualizar(Compras compra) async {
    try {
      if (compra.id == null) {
        throw Exception('El ID de la compra es requerido para actualizar');
      }

      // Validar antes de actualizar
      final errores = compra.validar();
      if (errores.isNotEmpty) {
        throw Exception('Datos inválidos: ${errores.join(', ')}');
      }

      final response = await _supabase
          .from(_tableName)
          .update(compra.toJson())
          .eq('id', compra.id!)
          .select()
          .single();

      return Compras.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar compra: $e');
    }
  }

  // Eliminar compra
  Future<void> eliminar(int id) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar compra: $e');
    }  }

  // Obtener estadísticas de compras
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final hoy = DateTime.now();
      final inicioMes = DateTime(hoy.year, hoy.month, 1);
      final finMes = DateTime(hoy.year, hoy.month + 1, 0);

      // Total de compras
      final totalCompras = await _supabase
          .from(_tableName)
          .select('id');

      // Compras del mes
      final comprasMes = await _supabase
          .from(_tableName)
          .select('cantidad, precio')
          .gte('fecha', inicioMes.toIso8601String())
          .lte('fecha', finMes.toIso8601String());

      double montoMes = 0;
      int cantidadComprasMes = comprasMes.length;

      for (final compra in comprasMes) {
        final cantidad = (compra['cantidad'] as num?)?.toDouble() ?? 0;
        final precio = (compra['precio'] as num?)?.toDouble() ?? 0;
        montoMes += cantidad * precio;
      }

      // Monto total histórico
      final todasCompras = await _supabase
          .from(_tableName)
          .select('cantidad, precio');

      double montoTotal = 0;
      for (final compra in todasCompras) {
        final cantidad = (compra['cantidad'] as num?)?.toDouble() ?? 0;
        final precio = (compra['precio'] as num?)?.toDouble() ?? 0;
        montoTotal += cantidad * precio;
      }

      return {
        'totalCompras': (totalCompras as List).length,
        'comprasMes': cantidadComprasMes,
        'montoMes': montoMes,
        'montoTotal': montoTotal,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Obtener compras recientes
  Future<List<Compras>> obtenerRecientes([int limite = 10]) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('fecha', ascending: false)
          .limit(limite);

      return (response as List)
          .map((json) => Compras.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener compras recientes: $e');
    }
  }

  // Obtener reporte de compras por periodo
  Future<List<Map<String, dynamic>>> obtenerReportePorPeriodo(
    DateTime fechaInicio, 
    DateTime fechaFin
  ) async {
    try {
      final response = await _supabase.rpc('reporte_compras_por_periodo', params: {
        'fecha_inicio': fechaInicio.toIso8601String(),
        'fecha_fin': fechaFin.toIso8601String(),
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback manual si no existe el stored procedure
      final compras = await obtenerPorRangoFechas(fechaInicio, fechaFin);
      
      Map<String, Map<String, dynamic>> reporte = {};
      
      for (final compra in compras) {
        final fecha = compra.fechaFormateada;
        if (!reporte.containsKey(fecha)) {
          reporte[fecha] = {
            'fecha': fecha,
            'cantidad_compras': 0,
            'monto_total': 0.0,
          };
        }
        
        reporte[fecha]!['cantidad_compras'] += 1;
        reporte[fecha]!['monto_total'] += compra.total;
      }
      
      return reporte.values.toList();
    }
  }
}
