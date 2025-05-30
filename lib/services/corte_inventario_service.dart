import '../models/corte_inventario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CorteInventarioService {
  static final CorteInventarioService _instance =
      CorteInventarioService._internal();
  factory CorteInventarioService() => _instance;
  CorteInventarioService._internal();

  final _supabase = Supabase.instance.client;

  Future<CorteInventario?> obtenerCorteActivo() async {
    try {
      final response =
          await _supabase
              .from('Corte_inventario')
              .select()
              .eq('estado', 'iniciado')
              .order('fecha_corte', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) return null;

      return CorteInventario.fromJson(response);
    } catch (e) {
      print('Error al obtener corte activo: $e');
      return null;
    }
  }

  Future<CorteInventario> iniciarCorte(Map<int, int> stockInicial) async {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Crear listas para guardar en la base de datos
    final idsMps = stockInicial.keys.toList();
    final stockInicialValues = stockInicial.values.toList();

    final response =
        await _supabase
            .from('Corte_inventario')
            .insert({
              'inicio_corte': timeStr,
              'fecha_corte': dateStr,
              'estado': 'iniciado',
              'ids_mps': idsMps,
              'stock_inicial': stockInicialValues,
            })
            .select()
            .single();

    return CorteInventario.fromJson(response);
  }

  Future<void> finalizarCorte(Map<int, int> stockFinal) async {
    final corteActivo = await obtenerCorteActivo();
    if (corteActivo == null) {
      throw Exception('No hay un corte activo para finalizar');
    }

    final idsMps = stockFinal.keys.toList();
    final stockFinalList = stockFinal.values.toList();
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    await _supabase
        .from('Corte_inventario')
        .update({
          'fin_corte': timeStr,
          'estado': 'finalizado',
          'ids_mps': idsMps,
          'stock_final': stockFinalList,
        })
        .eq('id', corteActivo.id);

    // Actualizar el stock de las materias primas
    for (final entry in stockFinal.entries) {
      await _supabase
          .from('Materia_prima')
          .update({'stock': entry.value})
          .eq('id', entry.key);
    }
  }

  Future<void> registrarStockInicial(Map<int, int> stockInicial) async {
    final corteActivo = await obtenerCorteActivo();
    if (corteActivo == null) {
      throw Exception('No hay un corte activo para registrar el stock inicial');
    }

    final idsMps = stockInicial.keys.toList();
    final stockInicialList = stockInicial.values.toList();

    await _supabase
        .from('Corte_inventario')
        .update({'ids_mps': idsMps, 'stock_inicial': stockInicialList})
        .eq('id', corteActivo.id);
  }

  Future<void> actualizarStockInicial(Map<int, int> materiasPrimas) async {
    try {
      final supabase = Supabase.instance.client;

      final corteActivo = await obtenerCorteActivo();
      if (corteActivo == null) {
        throw Exception('No hay un corte activo');
      }

      await supabase.from('stock_inicial_corte').insert({
        'corte_id': corteActivo.id,
        'datos_stock': materiasPrimas,
        'fecha_registro': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
