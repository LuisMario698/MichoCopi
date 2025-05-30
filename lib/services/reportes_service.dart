import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/venta.dart';
import '../models/producto.dart';

class ReportesService {
  static final _supabase = Supabase.instance.client;

  // ========== REPORTES DE VENTAS ==========

  // Obtener ventas por rango de fechas
  static Future<Map<String, dynamic>> obtenerVentasPorFecha({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final response = await _supabase
          .from('Ventas')
          .select('*')
          .gte('fecha', fechaInicio.toIso8601String())
          .lte('fecha', fechaFin.toIso8601String())
          .order('fecha', ascending: false);

      final ventas =
          (response as List).map((json) => Venta.fromJson(json)).toList();

      return {
        'success': true,
        'data': ventas,
        'message': 'Ventas obtenidas exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al obtener ventas: $e',
      };
    }
  }

  // Obtener resumen de ventas por período
  static Future<Map<String, dynamic>> obtenerResumenVentas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final ventasResult = await obtenerVentasPorFecha(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      if (!ventasResult['success']) {
        return ventasResult;
      }

      final ventas = ventasResult['data'] as List<Venta>;

      // Calcular estadísticas
      final totalVentas = ventas.length;
      final ingresoTotal = ventas.fold<double>(
        0,
        (sum, venta) => sum + venta.total,
      );
      final promedioVenta = totalVentas > 0 ? ingresoTotal / totalVentas : 0;

      // Agrupar por método de pago
      final ventasPorMetodoPago = <String, Map<String, dynamic>>{};
      for (final venta in ventas) {
        final metodo = venta.metodoPago ?? 'No especificado';
        if (!ventasPorMetodoPago.containsKey(metodo)) {
          ventasPorMetodoPago[metodo] = {'cantidad': 0, 'total': 0.0};
        }
        ventasPorMetodoPago[metodo]!['cantidad']++;
        ventasPorMetodoPago[metodo]!['total'] += venta.total;
      }

      // Agrupar por día
      final ventasPorDia = <String, Map<String, dynamic>>{};
      for (final venta in ventas) {
        final dia = venta.fecha.toIso8601String().split('T')[0];
        if (!ventasPorDia.containsKey(dia)) {
          ventasPorDia[dia] = {'cantidad': 0, 'total': 0.0};
        }
        ventasPorDia[dia]!['cantidad']++;
        ventasPorDia[dia]!['total'] += venta.total;
      }

      return {
        'success': true,
        'data': {
          'totalVentas': totalVentas,
          'ingresoTotal': ingresoTotal,
          'promedioVenta': promedioVenta,
          'ventasPorMetodoPago': ventasPorMetodoPago,
          'ventasPorDia': ventasPorDia,
          'ventas': ventas,
        },
        'message': 'Resumen de ventas generado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al generar resumen: $e',
      };
    }
  }

  // Obtener productos más vendidos
  static Future<Map<String, dynamic>> obtenerProductosMasVendidos({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int limite = 10,
  }) async {
    try {
      final ventasResult = await obtenerVentasPorFecha(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      if (!ventasResult['success']) {
        return ventasResult;
      }

      final ventas = ventasResult['data'] as List<Venta>;
      final conteoProductos = <int, int>{};

      // Contar productos vendidos
      for (final venta in ventas) {
        for (final idProducto in venta.idProductos) {
          conteoProductos[idProducto] = (conteoProductos[idProducto] ?? 0) + 1;
        }
      }

      // Obtener información de productos
      final productosVendidos = <Map<String, dynamic>>[];
      for (final entry in conteoProductos.entries) {
        try {
          final productoResponse =
              await _supabase
                  .from('Productos')
                  .select('*')
                  .eq('id', entry.key)
                  .single();

          final producto = Producto.fromJson(productoResponse);
          productosVendidos.add({
            'producto': producto,
            'cantidadVendida': entry.value,
          });
        } catch (e) {
          print('Error al obtener producto ${entry.key}: $e');
        }
      }

      // Ordenar por cantidad vendida
      productosVendidos.sort(
        (a, b) => (b['cantidadVendida'] as int).compareTo(
          a['cantidadVendida'] as int,
        ),
      );

      return {
        'success': true,
        'data': productosVendidos.take(limite).toList(),
        'message': 'Productos más vendidos obtenidos exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al obtener productos más vendidos: $e',
      };
    }
  }

  // ========== REPORTES DE INVENTARIO ==========

  // Obtener reporte de inventario actual
  static Future<Map<String, dynamic>> obtenerReporteInventario() async {
    try {
      final response = await _supabase
          .from('Productos')
          .select('*')
          .order('stock', ascending: true);

      final productos =
          (response as List).map((json) => Producto.fromJson(json)).toList();

      // Productos con stock bajo (menos de 10 unidades)
      final stockBajo = productos.where((p) => (p.stock ?? 0) < 10).toList();

      // Productos sin stock
      final sinStock = productos.where((p) => (p.stock ?? 0) == 0).toList();

      // Valor total del inventario
      final valorTotal = productos.fold<double>(
        0,
        (sum, p) => sum + (p.precio * (p.stock ?? 0)),
      );

      // Agrupar por categoría
      final porCategoria = <int, Map<String, dynamic>>{};
      for (final producto in productos) {
        final catId = producto.idCategoriaProducto;
        if (!porCategoria.containsKey(catId)) {
          porCategoria[catId] = {
            'cantidad': 0,
            'valor': 0.0,
            'productos': <Producto>[],
          };
        }
        porCategoria[catId]!['cantidad']++;
        porCategoria[catId]!['valor'] +=
            producto.precio * (producto.stock ?? 0);
        (porCategoria[catId]!['productos'] as List<Producto>).add(producto);
      }

      return {
        'success': true,
        'data': {
          'totalProductos': productos.length,
          'stockBajo': stockBajo,
          'sinStock': sinStock,
          'valorTotal': valorTotal,
          'porCategoria': porCategoria,
          'productos': productos,
        },
        'message': 'Reporte de inventario generado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al generar reporte de inventario: $e',
      };
    }
  }

  // ========== REPORTES DE CORTES DE INVENTARIO ==========

  // Obtener reporte de cortes de inventario
  static Future<Map<String, dynamic>> obtenerReporteCortes({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      var query = _supabase.from('Corte_inventario').select('*');

      if (fechaInicio != null) {
        query = query.gte(
          'fecha_corte',
          fechaInicio.toIso8601String().split('T')[0],
        );
      }
      if (fechaFin != null) {
        query = query.lte(
          'fecha_corte',
          fechaFin.toIso8601String().split('T')[0],
        );
      }

      final response = await query.order('fecha_corte', ascending: false);
      final cortes = response as List;

      // Calcular estadísticas generales
      final totalCortes = cortes.length;
      final cortesCompletados =
          cortes.where((c) => c['estado'] == 'completado').length;
      final cortesEnProceso =
          cortes.where((c) => c['estado'] == 'iniciado').length;

      return {
        'success': true,
        'data': {
          'totalCortes': totalCortes,
          'cortesCompletados': cortesCompletados,
          'cortesEnProceso': cortesEnProceso,
          'cortes': cortes,
        },
        'message': 'Reporte de cortes de inventario generado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al generar reporte de cortes: $e',
      };
    }
  }

  // Obtener detalles de un corte específico
  static Future<Map<String, dynamic>> obtenerDetalleCorte(int idCorte) async {
    try {
      // Obtener información del corte
      final corteResponse =
          await _supabase
              .from('Corte_inventario')
              .select('*')
              .eq('id', idCorte)
              .single();

      // Obtener reportes detallados del corte (si existen)
      final reportesResponse = await _supabase
          .from('Reportes_cortes')
          .select('*, Materia_prima!inner(*)')
          .eq('id_corte', idCorte);

      final reportes = reportesResponse as List;

      // Si no hay reportes detallados, generar desde los arrays del corte
      List<Map<String, dynamic>> diferenciasCalculadas = [];

      if (reportes.isEmpty && corteResponse['ids_mps'] != null) {
        final idsMps = List<int>.from(corteResponse['ids_mps']);
        final stockInicial =
            corteResponse['stock_inicial'] != null
                ? List<int>.from(corteResponse['stock_inicial'])
                : <int>[];
        final stockFinal =
            corteResponse['stock_final'] != null
                ? List<int>.from(corteResponse['stock_final'])
                : <int>[];

        for (int i = 0; i < idsMps.length; i++) {
          final inicial = i < stockInicial.length ? stockInicial[i] : 0;
          final final_ = i < stockFinal.length ? stockFinal[i] : 0;
          final diferencia = final_ - inicial;
          final porcentaje = inicial > 0 ? (diferencia / inicial * 100) : 0.0;

          // Obtener info de la materia prima
          try {
            final mpResponse =
                await _supabase
                    .from('Materia_prima')
                    .select('*')
                    .eq('id', idsMps[i])
                    .single();

            diferenciasCalculadas.add({
              'id_materia_prima': idsMps[i],
              'nombre_mp': mpResponse['nombre'],
              'stock_inicial': inicial,
              'stock_final': final_,
              'diferencia': diferencia,
              'porcentaje_diferencia': porcentaje,
            });
          } catch (e) {
            print('Error al obtener MP ${idsMps[i]}: $e');
          }
        }
      }

      // Calcular estadísticas del corte
      final materiasAfectadas =
          reportes.isNotEmpty ? reportes.length : diferenciasCalculadas.length;
      final diferenciasPositivas =
          reportes.isNotEmpty
              ? reportes.where((r) => r['diferencia'] > 0).length
              : diferenciasCalculadas.where((d) => d['diferencia'] > 0).length;
      final diferenciasNegativas =
          reportes.isNotEmpty
              ? reportes.where((r) => r['diferencia'] < 0).length
              : diferenciasCalculadas.where((d) => d['diferencia'] < 0).length;

      return {
        'success': true,
        'data': {
          'corte': corteResponse,
          'reportes': reportes.isNotEmpty ? reportes : diferenciasCalculadas,
          'estadisticas': {
            'materiasAfectadas': materiasAfectadas,
            'diferenciasPositivas': diferenciasPositivas,
            'diferenciasNegativas': diferenciasNegativas,
            'exactas':
                materiasAfectadas - diferenciasPositivas - diferenciasNegativas,
          },
        },
        'message': 'Detalle del corte obtenido exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al obtener detalle del corte: $e',
      };
    }
  }

  // Guardar reporte detallado de corte
  static Future<Map<String, dynamic>> guardarReporteCorte({
    required int idCorte,
    required List<Map<String, dynamic>> diferencias,
    String? observaciones,
  }) async {
    try {
      // Limpiar reportes existentes del corte
      await _supabase.from('Reportes_cortes').delete().eq('id_corte', idCorte);

      // Insertar nuevos reportes
      final reportesParaInsertar =
          diferencias
              .map(
                (dif) => {
                  'id_corte': idCorte,
                  'id_materia_prima': dif['id_materia_prima'],
                  'stock_inicial': dif['stock_inicial'],
                  'stock_final': dif['stock_final'],
                  'diferencia': dif['diferencia'],
                  'porcentaje_diferencia': dif['porcentaje_diferencia'],
                  'fecha_corte':
                      dif['fecha_corte'] ??
                      DateTime.now().toIso8601String().split('T')[0],
                  'observaciones': observaciones,
                },
              )
              .toList();

      await _supabase.from('Reportes_cortes').insert(reportesParaInsertar);

      return {
        'success': true,
        'data': null,
        'message': 'Reporte de corte guardado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al guardar reporte de corte: $e',
      };
    }
  }

  // ========== REPORTES FINANCIEROS ==========

  // Obtener resumen financiero por período (Solo ventas por ahora)
  static Future<Map<String, dynamic>> obtenerResumenFinanciero({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      // Obtener ventas (ingresos)
      final ventasResult = await obtenerResumenVentas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      double ingresos = 0;
      // Las compras están desactivadas por el momento
      double egresos = 0; // Temporal - sin compras

      if (ventasResult['success']) {
        ingresos = ventasResult['data']['ingresoTotal'] ?? 0;
      }

      final utilidad = ingresos - egresos;
      final margenUtilidad = ingresos > 0 ? (utilidad / ingresos) * 100 : 0;

      return {
        'success': true,
        'data': {
          'ingresos': ingresos,
          'egresos': egresos,
          'utilidad': utilidad,
          'margenUtilidad': margenUtilidad,
          'ventasDetalle':
              ventasResult['success'] ? ventasResult['data'] : null,
          // 'comprasDetalle': null, // Desactivado temporalmente
        },
        'message': 'Resumen financiero generado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al generar resumen financiero: $e',
      };
    }
  }

  // ========== REPORTES DE PRODUCTOS ==========

  // Obtener reporte detallado de productos
  static Future<Map<String, dynamic>> obtenerReporteProductos() async {
    try {
      final response = await _supabase
          .from('Productos')
          .select('*')
          .order('nombre', ascending: true);

      final productos =
          (response as List).map((json) => Producto.fromJson(json)).toList();

      // Calcular estadísticas
      final totalProductos = productos.length;
      final valorInventario = productos.fold<double>(
        0,
        (sum, p) => sum + (p.precio * (p.stock ?? 0)),
      );
      final promedioprecio =
          totalProductos > 0
              ? productos.fold<double>(0, (sum, p) => sum + p.precio) /
                  totalProductos
              : 0;

      // Productos más caros
      final productosMasCaros = [...productos]
        ..sort((a, b) => b.precio.compareTo(a.precio));

      // Productos con mayor valor en inventario
      final mayorValorInventario = [...productos]..sort(
        (a, b) =>
            (b.precio * (b.stock ?? 0)).compareTo(a.precio * (a.stock ?? 0)),
      );

      // Agrupar por categoría
      final porCategoria = <int, Map<String, dynamic>>{};
      for (final producto in productos) {
        final catId = producto.idCategoriaProducto;
        if (!porCategoria.containsKey(catId)) {
          porCategoria[catId] = {
            'cantidad': 0,
            'valorInventario': 0.0,
            'productos': <Producto>[],
          };
        }
        porCategoria[catId]!['cantidad']++;
        porCategoria[catId]!['valorInventario'] +=
            producto.precio * (producto.stock ?? 0);
        (porCategoria[catId]!['productos'] as List<Producto>).add(producto);
      }

      return {
        'success': true,
        'data': {
          'totalProductos': totalProductos,
          'valorInventario': valorInventario,
          'promedioprecio': promedioprecio,
          'productosMasCaros': productosMasCaros.take(10).toList(),
          'mayorValorInventario': mayorValorInventario.take(10).toList(),
          'porCategoria': porCategoria,
          'productos': productos,
        },
        'message': 'Reporte de productos generado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al generar reporte de productos: $e',
      };
    }
  }
  // ========== UTILIDADES ADICIONALES ==========

  // Exportar ventas a CSV
  static Future<Map<String, dynamic>> exportarVentasCSV({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final ventasResult = await obtenerVentasPorFecha(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      if (!ventasResult['success']) {
        return ventasResult;
      }

      final ventas = ventasResult['data'] as List<Venta>;
      String csv = 'ID,Fecha,Total,Método de Pago,Cliente,Productos\n';

      for (final venta in ventas) {
        csv +=
            '${venta.id ?? ""},${venta.fecha.toIso8601String()},${venta.total},${venta.metodoPago ?? "No especificado"},${venta.cliente ?? ""},${venta.idProductos.join(";")}\n';
      }

      return {
        'success': true,
        'data': csv,
        'message': 'CSV de ventas generado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': '',
        'message': 'Error al generar CSV de ventas: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> exportarProductosCSV() async {
    try {
      final productosResult = await obtenerReporteProductos();

      if (!productosResult['success']) {
        return productosResult;
      }

      final productos = productosResult['data']['productos'] as List<Producto>;
      String csv = 'ID,Nombre,Precio,Stock,Categoría\n';

      for (final producto in productos) {
        csv +=
            '${producto.id ?? ""},${producto.nombre},${producto.precio},${producto.stock ?? 0},${producto.idCategoriaProducto}\n';
      }

      return {
        'success': true,
        'data': csv,
        'message': 'CSV de productos generado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': '',
        'message': 'Error al generar CSV de productos: $e',
      };
    }
  }
}
