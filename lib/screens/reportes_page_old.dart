import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/reportes_service.dart';
import '../models/producto.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  bool _cargando = false;
  
  // Datos de reportes
  Map<String, dynamic>? _resumenVentas;
  List<Map<String, dynamic>>? _productosMasVendidos;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarTodosLosReportes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodosLosReportes() async {
    if (_cargando) return;

    setState(() {
      _cargando = true;
    });

    try {
      // Cargar todos los reportes necesarios
      final futures = await Future.wait([
        ReportesService.obtenerResumenVentas(
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        ),
        ReportesService.obtenerProductosMasVendidos(
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        ),
        // Aquí puedes añadir más reportes si es necesario
      ]);

      if (!mounted) return;

      setState(() {
        // Procesar resultados
        final resumenResult = futures[0];
        final productosResult = futures[1];

        if (resumenResult['success']) {
          _resumenVentas = resumenResult['data'];
        }
        if (productosResult['success']) {
          _productosMasVendidos = List<Map<String, dynamic>>.from(
            productosResult['data'],
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los reportes: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _cargarTodosLosReportes,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cargarReporte() async {
    setState(() {
      _cargando = true;
    });

    try {
      if (!mounted) return;

      final resultados = await Future.wait([
        ReportesService.obtenerResumenVentas(
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        ),
        ReportesService.obtenerProductosMasVendidos(
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        ),
      ]);

      if (!mounted) return;

      final resumenResult = resultados[0];
      final productosResult = resultados[1];

      setState(() {
        if (resumenResult['success']) {
          _resumenVentas = resumenResult['data'];
        }
        if (productosResult['success']) {
          _productosMasVendidos = List<Map<String, dynamic>>.from(
            productosResult['data'],
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar reporte: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _cargarReporte,
          ),
        ),
      );
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
      _cargarReporte();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Reportes de Ventas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC2185B),
                  ),
                ),
                const Spacer(),
                // Selector de fechas
                _buildFechaSelector(),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _buildContenidoReporte(),
          ),
        ],
      ),
    );
  }

  Widget _buildFechaSelector() {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Row(
      children: [
        const Text('Período: '),
        TextButton(
          onPressed: () => _seleccionarFecha(true),
          child: Text(formatoFecha.format(_fechaInicio)),
        ),
        const Text(' - '),
        TextButton(
          onPressed: () => _seleccionarFecha(false),
          child: Text(formatoFecha.format(_fechaFin)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _cargarReporte,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC2185B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Actualizar'),
        ),
      ],
    );
  }

  Widget _buildContenidoReporte() {
    if (_resumenVentas == null) {
      return const Center(
        child: Text('No hay datos disponibles para el período seleccionado'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetas de resumen
          _buildTarjetasResumen(),
          const SizedBox(height: 24),

          // Gráficos y tablas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildVentasPorDia(),
                    const SizedBox(height: 16),
                    _buildVentasPorMetodoPago(),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Columna derecha
              Expanded(flex: 1, child: _buildProductosMasVendidos()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetasResumen() {
    return Row(
      children: [
        Expanded(
          child: _buildTarjetaEstadistica(
            'Total de Ventas',
            '${_resumenVentas!['totalVentas']}',
            Icons.shopping_cart,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTarjetaEstadistica(
            'Ingresos Totales',
            '\$${_resumenVentas!['ingresoTotal'].toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTarjetaEstadistica(
            'Promedio por Venta',
            '\$${_resumenVentas!['promedioVenta'].toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaEstadistica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVentasPorDia() {
    final ventasPorDia = _resumenVentas!['ventasPorDia'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas por Día',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ventasPorDia.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(
                            DateTime.parse(entry.key),
                          ),
                        ),
                        Text(
                          '${entry.value['cantidad']} ventas - \$${entry.value['total'].toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVentasPorMetodoPago() {
    final ventasPorMetodo =
        _resumenVentas!['ventasPorMetodoPago'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas por Método de Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ventasPorMetodo.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          '${entry.value['cantidad']} ventas - \$${entry.value['total'].toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductosMasVendidos() {
    if (_productosMasVendidos == null || _productosMasVendidos!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos de productos'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos Más Vendidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._productosMasVendidos!.map((item) {
              final producto = item['producto'] as Producto;
              final cantidad = item['cantidadVendida'] as int;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(producto.nombre)),
                    Text('$cantidad unidades'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
