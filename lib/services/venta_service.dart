import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/venta.dart';
import '../models/carrito_item.dart';

class VentaService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Crear una nueva venta
  static Future<Map<String, dynamic>> crearVenta(Venta venta) async {
    try {
      // Validaciones iniciales
      if (venta.idProductos.isEmpty) {
        return {
          'success': false,
          'message': 'La venta debe contener al menos un producto',
        };
      }

      if (venta.total <= 0) {
        return {'success': false, 'message': 'El total debe ser mayor a 0'};
      }

      if (venta.pago < venta.total) {
        return {
          'success': false,
          'message': 'El pago no puede ser menor al total',
        };
      } // Verificar que todos los productos existen
      for (int idProducto in venta.idProductos) {
        final productoResponse =
            await _client
                .from('Productos')
                .select('id')
                .eq('id', idProducto)
                .maybeSingle();

        if (productoResponse == null) {
          return {
            'success': false,
            'message': 'El producto con ID $idProducto no existe',
          };
        }
      }      // Preparar datos para insertar usando el método específico
      final ventaData = venta.toJsonForInsert();

      // Insertar la venta
      final response =
          await _client
              .from('Ventas')
              .insert(ventaData)
              .select()
              .single();// Ya no actualizamos el stock de productos vendidos
      for (int idProducto in venta.idProductos) {
        // Verificar que el producto aún existe
        await _client
            .from('Productos')
            .select('id')
            .eq('id', idProducto)
            .single();
      }

      final ventaCreada = Venta.fromJson(response);

      print('✅ Venta creada exitosamente: ${ventaCreada.id}');
      return {
        'success': true,
        'message': 'Venta registrada exitosamente',
        'data': ventaCreada,
      };
    } on PostgrestException catch (e) {
      print('❌ Error PostgreSQL: ${e.message}');
      String userMessage = 'Error al registrar la venta';

      if (e.code == '23505') {
        userMessage = 'Ya existe una venta con estos datos';
      } else if (e.code == '23503') {
        userMessage = 'Referencia de datos inválida';
      }

      return {'success': false, 'message': userMessage, 'details': e.message};
    } catch (e) {
      print('❌ Error general: $e');
      return {
        'success': false,
        'message': 'Error inesperado al crear la venta',
        'details': e.toString(),
      };
    }
  }

  // Obtener todas las ventas
  static Future<Map<String, dynamic>> obtenerVentas() async {
    try {
      final response = await _client
          .from('Ventas')
          .select()
          .order('fecha', ascending: false);

      final ventas =
          (response as List).map((json) => Venta.fromJson(json)).toList();

      return {
        'success': true,
        'data': ventas,
        'message': 'Ventas obtenidas exitosamente',
      };
    } catch (e) {
      print('❌ Error al obtener ventas: $e');
      return {
        'success': false,
        'message': 'Error al obtener las ventas',
        'details': e.toString(),
      };
    }
  }

  // Obtener venta por ID
  static Future<Map<String, dynamic>> obtenerVentaPorId(int id) async {
    try {
      final response =
          await _client.from('Ventas').select().eq('id', id).maybeSingle();

      if (response == null) {
        return {'success': false, 'message': 'Venta no encontrada'};
      }

      final venta = Venta.fromJson(response);

      return {'success': true, 'data': venta, 'message': 'Venta encontrada'};
    } catch (e) {
      print('❌ Error al obtener venta: $e');
      return {
        'success': false,
        'message': 'Error al obtener la venta',
        'details': e.toString(),
      };
    }
  }

  // Obtener ventas por usuario
  static Future<Map<String, dynamic>> obtenerVentasPorUsuario(
    int idUsuario,
  ) async {
    try {
      final response = await _client
          .from('Ventas')
          .select()
          .eq('id_Usuario', idUsuario)
          .order('fecha', ascending: false);

      final ventas =
          (response as List).map((json) => Venta.fromJson(json)).toList();

      return {
        'success': true,
        'data': ventas,
        'message': 'Ventas del usuario obtenidas exitosamente',
      };
    } catch (e) {
      print('❌ Error al obtener ventas por usuario: $e');
      return {
        'success': false,
        'message': 'Error al obtener las ventas del usuario',
        'details': e.toString(),
      };
    }
  }

  // Obtener ventas por fecha
  static Future<Map<String, dynamic>> obtenerVentasPorFecha(
    DateTime fecha,
  ) async {
    try {
      final fechaStr =
          fecha.toIso8601String().split('T')[0]; // Solo la fecha, sin hora

      final response = await _client
          .from('Ventas')
          .select()
          .gte('fecha', '${fechaStr}T00:00:00.000Z')
          .lt('fecha', '${fechaStr}T23:59:59.999Z')
          .order('fecha', ascending: false);

      final ventas =
          (response as List).map((json) => Venta.fromJson(json)).toList();

      return {
        'success': true,
        'data': ventas,
        'message': 'Ventas del día obtenidas exitosamente',
      };
    } catch (e) {
      print('❌ Error al obtener ventas por fecha: $e');
      return {
        'success': false,
        'message': 'Error al obtener las ventas del día',
        'details': e.toString(),
      };
    }
  }

  // Calcular total de ventas del día
  static Future<Map<String, dynamic>> obtenerTotalVentasHoy() async {
    try {
      final hoy = DateTime.now();
      final fechaStr = hoy.toIso8601String().split('T')[0];

      final response = await _client
          .from('Ventas')
          .select('total')
          .gte('fecha', '${fechaStr}T00:00:00.000Z')
          .lt('fecha', '${fechaStr}T23:59:59.999Z');

      double totalDia = 0.0;
      int cantidadVentas = 0;

      for (var venta in response) {
        totalDia += (venta['total'] as num).toDouble();
        cantidadVentas++;
      }

      return {
        'success': true,
        'data': {
          'total': totalDia,
          'cantidad_ventas': cantidadVentas,
          'fecha': fechaStr,
        },
        'message': 'Total de ventas calculado exitosamente',
      };
    } catch (e) {
      print('❌ Error al calcular total de ventas: $e');
      return {
        'success': false,
        'message': 'Error al calcular el total de ventas',
        'details': e.toString(),
      };
    }
  }

  // Obtener estadísticas de ventas
  static Future<Map<String, dynamic>> obtenerEstadisticasVentas() async {
    try {
      final todasVentas = await _client.from('Ventas').select('total, fecha');

      double totalGeneral = 0.0;
      int cantidadTotal = todasVentas.length;

      for (var venta in todasVentas) {
        totalGeneral += (venta['total'] as num).toDouble();
      }

      double promedio = cantidadTotal > 0 ? totalGeneral / cantidadTotal : 0.0;

      return {
        'success': true,
        'data': {
          'total_general': totalGeneral,
          'cantidad_ventas': cantidadTotal,
          'promedio_venta': promedio,
        },
        'message': 'Estadísticas obtenidas exitosamente',
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {
        'success': false,
        'message': 'Error al obtener estadísticas de ventas',
        'details': e.toString(),
      };
    }
  }

  // Verificar si un producto tiene ventas registradas
  static Future<bool> productoTieneVentas(int idProducto) async {
    try {
      final response = await _client
          .from('Ventas')
          .select('id')
          .contains('id_Productos', [idProducto])
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar ventas del producto: $e');
      return false;
    }
  }  // Procesar venta desde carritoItems
  static Future<Map<String, dynamic>> procesarVenta({
    required List<CarritoItem> carrito,
    required double pago,
    required double cambio,
    bool pagoEnDolares = false,
    double? tipoCambio,
  }) async {
    try {
      if (carrito.isEmpty) {
        return {'success': false, 'message': 'El carrito está vacío'};
      }

      // Verificar que los productos existan
      for (var item in carrito) {
        final productoResponse =
            await _client
                .from('Productos')
                .select('id')
                .eq('id', item.productoId)
                .maybeSingle();

        if (productoResponse == null) {
          return {
            'success': false,
            'message': 'El producto ${item.nombre} ya no está disponible',
          };
        }
      }

      // Calcular el total
      double total = 0.0;
      for (var item in carrito) {
        total += item.subtotal;
      }

      // Crear lista de IDs de productos (considerando la cantidad)
      List<int> idProductos = [];
      for (var item in carrito) {
        for (int i = 0; i < item.cantidad; i++) {
          idProductos.add(item.productoId);
        }
      }      // En un entorno real, aquí se haría el cobro y se registraría el pago
      // Usar los valores proporcionados en lugar de calcular automáticamente
      
      // Obtener ID del usuario (asumimos un usuario fijo para simplificar)
      int idUsuario = 1; // Usuario predeterminado, ajustar según tu sistema

      // Determinar el método de pago y tipo de cambio
      String metodoPago = pagoEnDolares ? 'USD' : 'MXN';
      double? tipoCambioVenta = pagoEnDolares ? tipoCambio : null;      // Crear objeto Venta con la información completa
      final nuevaVenta = Venta(
        idProductos: idProductos,
        total: total,
        fecha: DateTime.now(),
        pago: pago,
        cambio: cambio,
        idUsuario: idUsuario,
        metodoPago: metodoPago,
        tipoCambio: tipoCambioVenta,
      );// Insertar la venta usando el método específico para insertar
      final response =
          await _client
              .from('Ventas')
              .insert(nuevaVenta.toJsonForInsert())
              .select()
              .single();

      final ventaCreada = Venta.fromJson(response);

      return {
        'success': true,
        'message': 'Venta procesada exitosamente',
        'venta_id': ventaCreada.id,
        'data': ventaCreada,
      };
    } on PostgrestException catch (e) {
      print('❌ Error PostgreSQL al procesar venta: ${e.message}');
      return {
        'success': false,
        'message': 'Error al procesar la venta: ${e.message}',
      };
    } catch (e) {
      print('❌ Error general al procesar venta: $e');
      return {
        'success': false,
        'message': 'Error inesperado al procesar la venta',
        'details': e.toString(),
      };
    }
  }
}
