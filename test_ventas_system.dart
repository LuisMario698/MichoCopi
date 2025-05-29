// Script de prueba para el sistema de ventas
// filepath: c:\Users\LuisM\OneDrive\Escritorio\MichoCopi\test_ventas_system.dart

import 'package:flutter/material.dart';
import 'lib/services/venta_service.dart';
import 'lib/services/producto_service.dart';
import 'lib/models/carrito_item.dart';
import 'lib/models/producto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 === PRUEBA DEL SISTEMA DE VENTAS ===');
  print('📅 Fecha: ${DateTime.now()}');
  print('');
  
  // Prueba 1: Verificar conexión y obtener productos
  await pruebaObtenerProductos();
  
  // Prueba 2: Simular una venta
  await pruebaVentaCompleta();
  
  // Prueba 3: Obtener ventas
  await pruebaObtenerVentas();
  
  print('');
  print('✅ === PRUEBAS COMPLETADAS ===');
}

Future<void> pruebaObtenerProductos() async {
  print('🔍 PRUEBA 1: Obtener productos...');
  
  try {
    final resultado = await ProductoService.obtenerProductos();
    
    if (resultado['success']) {
      final productos = resultado['data'] as List<Producto>;
      print('✅ Productos obtenidos: ${productos.length}');
      
      if (productos.isNotEmpty) {
        print('📦 Primer producto: ${productos.first.nombre} - Stock: ${productos.first.stock}');
      }
    } else {
      print('❌ Error al obtener productos: ${resultado['message']}');
    }
  } catch (e) {
    print('❌ Excepción en obtenerProductos: $e');
  }
  
  print('');
}

Future<void> pruebaVentaCompleta() async {
  print('💰 PRUEBA 2: Procesar venta completa...');
  
  try {
    // Primero obtener algunos productos
    final resultadoProductos = await ProductoService.obtenerProductos();
    
    if (!resultadoProductos['success'] || (resultadoProductos['data'] as List).isEmpty) {
      print('❌ No hay productos disponibles para la prueba');
      return;
    }
    
    final productos = resultadoProductos['data'] as List<Producto>;
    final productosConStock = productos.where((p) => p.stock > 0).take(2).toList();
    
    if (productosConStock.isEmpty) {
      print('❌ No hay productos con stock para la prueba');
      return;
    }
    
    // Crear carrito de prueba
    final carrito = <CarritoItem>[];
    
    for (int i = 0; i < productosConStock.length && i < 2; i++) {
      final producto = productosConStock[i];
      final cantidad = producto.stock >= 2 ? 2 : 1;
      
      carrito.add(CarritoItem(
        producto: producto,
        cantidad: cantidad,
      ));
      
      print('🛒 Agregado al carrito: ${producto.nombre} x$cantidad');
    }
    
    if (carrito.isEmpty) {
      print('❌ No se pudo crear carrito de prueba');
      return;
    }
    
    // Procesar la venta
    print('💳 Procesando venta...');
    final resultadoVenta = await VentaService.procesarVenta(
      carrito: carrito,
      cliente: 'Cliente de Prueba - ${DateTime.now().millisecondsSinceEpoch}',
    );
    
    if (resultadoVenta['success']) {
      print('✅ Venta procesada exitosamente!');
      print('🆔 ID de venta: ${resultadoVenta['venta_id']}');
      print('💰 Total: \$${resultadoVenta['total']}');
    } else {
      print('❌ Error al procesar venta: ${resultadoVenta['message']}');
    }
    
  } catch (e) {
    print('❌ Excepción en pruebaVentaCompleta: $e');
  }
  
  print('');
}

Future<void> pruebaObtenerVentas() async {
  print('📊 PRUEBA 3: Obtener historial de ventas...');
  
  try {
    final resultado = await VentaService.obtenerVentas();
    
    if (resultado['success']) {
      final ventas = resultado['data'] as List;
      print('✅ Ventas obtenidas: ${ventas.length}');
      
      if (ventas.isNotEmpty) {
        final ultimaVenta = ventas.first;
        print('📄 Última venta: ID ${ultimaVenta.id} - Cliente: ${ultimaVenta.cliente ?? 'Anónimo'} - Total: \$${ultimaVenta.total}');
      }
    } else {
      print('❌ Error al obtener ventas: ${resultado['message']}');
    }
  } catch (e) {
    print('❌ Excepción en pruebaObtenerVentas: $e');
  }
  
  print('');
}
