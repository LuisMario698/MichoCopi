import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/venta.dart';
import '../models/producto.dart';
import '../models/usuario.dart';
import '../models/compras.dart';
import '../models/proveedor.dart';
import '../models/materia_prima.dart';
import '../models/categoria_producto.dart';
import '../models/categoria_proveedor.dart';

class ReportesService {
  static final _supabase = Supabase.instance.client;

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
                  .from('productos')
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
          .from('productos')
          .select('*, categorias_productos!inner(*)')
          .order('stock', ascending: true);

      final productos = (response as List).map((json) => Producto.fromJson(json)).toList();

      // Productos con stock bajo (menos de 10 unidades)
      final stockBajo = productos.where((p) => (p.stock ?? 0) < 10).toList();
      
      // Productos sin stock
      final sinStock = productos.where((p) => (p.stock ?? 0) == 0).toList();
      
      // Valor total del inventario
      final valorTotal = productos.fold<double>(0, (sum, p) => sum + (p.precio * (p.stock ?? 0)));
      
      // Agrupar por categoría
      final porCategoria = <String, Map<String, dynamic>>{};
      for (final producto in productos) {
        final categoria = 'Categoría ${producto.idCategoriaProducto}';
        if (!porCategoria.containsKey(categoria)) {
          porCategoria[categoria] = {'cantidad': 0, 'valor': 0.0, 'productos': <Producto>[]};
        }
        porCategoria[categoria]!['cantidad']++;
        porCategoria[categoria]!['valor'] += producto.precio * (producto.stock ?? 0);
        (porCategoria[categoria]!['productos'] as List<Producto>).add(producto);
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

  // Obtener movimientos de inventario
  static Future<Map<String, dynamic>> obtenerMovimientosInventario({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      // Obtener ventas (salidas de inventario)
      final ventasResult = await obtenerVentasPorFecha(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      // Obtener compras (entradas de inventario)
      final comprasResponse = await _supabase
          .from('Compras')
          .select('*')
          .gte('fecha', fechaInicio.toIso8601String())
          .lte('fecha', fechaFin.toIso8601String())
          .order('fecha', ascending: false);

      final compras = (comprasResponse as List).map((json) => Compras.fromJson(json)).toList();

      return {
        'success': true,
        'data': {
          'ventas': ventasResult['success'] ? ventasResult['data'] : [],
          'compras': compras,
          'totalVentas': ventasResult['success'] ? (ventasResult['data'] as List).length : 0,
          'totalCompras': compras.length,
          'valorVentas': ventasResult['success'] 
              ? (ventasResult['data'] as List<Venta>).fold<double>(0, (sum, v) => sum + v.total)
              : 0.0,
          'valorCompras': compras.fold<double>(0, (sum, c) => sum + c.total),
        },
        'message': 'Movimientos de inventario obtenidos exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error al obtener movimientos de inventario: $e',
      };
    }
  }

  // ========== REPORTES FINANCIEROS ==========
  // Obtener resumen financiero por período (Solo ventas)
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
          'ventasDetalle': ventasResult['success'] ? ventasResult['data'] : null,
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
          .from('productos')
          .select('*, categorias_productos!inner(*)')
          .order('nombre', ascending: true);

      final productos = (response as List).map((json) => Producto.fromJson(json)).toList();

      // Calcular estadísticas
      final totalProductos = productos.length;
      final valorInventario = productos.fold<double>(0, (sum, p) => sum + (p.precio * (p.stock ?? 0)));
      final promedioprecio = totalProductos > 0 
          ? productos.fold<double>(0, (sum, p) => sum + p.precio) / totalProductos 
          : 0;

      // Productos más caros
      final productosMasCaros = [...productos]..sort((a, b) => b.precio.compareTo(a.precio));

      // Productos con mayor valor en inventario
      final mayorValorInventario = [...productos]
        ..sort((a, b) => (b.precio * (b.stock ?? 0)).compareTo(a.precio * (a.stock ?? 0)));

      // Agrupar por categoría
      final porCategoria = <int, Map<String, dynamic>>{};
      for (final producto in productos) {
        final catId = producto.idCategoriaProducto;
        if (!porCategoria.containsKey(catId)) {
          porCategoria[catId] = {
            'cantidad': 0, 
            'valorInventario': 0.0, 
            'productos': <Producto>[]
          };
        }
        porCategoria[catId]!['cantidad']++;
        porCategoria[catId]!['valorInventario'] += producto.precio * (producto.stock ?? 0);
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

  // Exportar datos a CSV (simulado - retorna string)
  static String exportarVentasCSV(List<Venta> ventas) {
    String csv = 'ID,Fecha,Total,Método de Pago,Productos\n';
    for (final venta in ventas) {
      csv += '${venta.id},${venta.fecha.toIso8601String()},${venta.total},${venta.metodoPago ?? ""},${venta.idProductos.join(";")}\n';
    }
    return csv;
  }

  static String exportarComprasCSV(List<Compras> compras) {
    String csv = 'ID,Fecha,Total,ID Proveedor,ID Materia Prima\n';
    for (final compra in compras) {
      csv += '${compra.id},${compra.fecha.toIso8601String()},${compra.total},${compra.idProveedor ?? ""},${compra.idMp ?? ""}\n';
    }
    return csv;
  }

  static String exportarProductosCSV(List<Producto> productos) {
    String csv = 'ID,Nombre,Precio,Stock,Categoría\n';
    for (final producto in productos) {
      csv += '${producto.id},${producto.nombre},${producto.precio},${producto.stock ?? 0},${producto.idCategoriaProducto}\n';
    }
    return csv;
  }
}
