import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/reportes_service.dart';
import '../models/venta.dart';
import '../models/producto.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  bool _cargando = false;

  // Datos de reportes
  Map<String, dynamic>? _resumenVentas;
  List<Map<String, dynamic>>? _productosMasVendidos;
  Map<String, dynamic>? _reporteInventario;
  Map<String, dynamic>? _resumenFinanciero;

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
    setState(() {
      _cargando = true;
    });

    try {
      final futures = await Future.wait([
        ReportesService.obtenerResumenVentas(
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        ),
        ReportesService.obtenerProductosMasVendidos(
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        ),
        ReportesService.obtenerReporteInventario(),
        ReportesService.obtenerResumenFinanciero(
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        ),
      ]);

      setState(() {
        if (futures[0]['success']) _resumenVentas = futures[0]['data'];
        if (futures[1]['success'])
          _productosMasVendidos = List<Map<String, dynamic>>.from(
            futures[1]['data'],
          );
        if (futures[2]['success']) _reporteInventario = futures[2]['data'];
        if (futures[3]['success']) _resumenFinanciero = futures[3]['data'];
      });
    } catch (e) {
      _mostrarError('Error al cargar reportes: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFFC2185B)),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
          if (_fechaInicio.isAfter(_fechaFin)) {
            _fechaFin = _fechaInicio.add(const Duration(days: 1));
          }
        } else {
          _fechaFin = fecha;
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaInicio = _fechaFin.subtract(const Duration(days: 1));
          }
        }
      });
      _cargarTodosLosReportes();
    }
  }

  Future<void> _exportarCSV(String tipoReporte) async {
    setState(() {
      _cargando = true;
    });

    try {
      String csvData = '';
      String nombreArchivo = '';

      switch (tipoReporte) {
        case 'ventas':
          final result = await ReportesService.exportarVentasCSV(
            fechaInicio: _fechaInicio,
            fechaFin: _fechaFin,
          );
          if (result['success']) {
            csvData = result['data'];
            nombreArchivo =
                'ventas_${DateFormat('yyyy-MM-dd').format(_fechaInicio)}_${DateFormat('yyyy-MM-dd').format(_fechaFin)}.csv';
          }
          break;
        case 'productos':
          final result = await ReportesService.exportarProductosCSV();
          if (result['success']) {
            csvData = result['data'];
            nombreArchivo =
                'productos_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
          }
          break;
      }

      if (csvData.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: csvData));
        _mostrarExito(
          'Datos CSV copiados al portapapeles. Nombre sugerido: $nombreArchivo',
        );
      }
    } catch (e) {
      _mostrarError('Error al exportar: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Column(
            children: [
              // Header mejorado
              _buildHeader(),

              // Tabs
              _buildTabBar(),

              // Contenido de las tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(),
                    _buildVentasTab(),
                    _buildInventarioTab(),
                    _buildFinancieroTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_cargando)
          Stack(
            children: [
              ModalBarrier(
                color: Colors.black.withOpacity(0.3),
                dismissible: false,
              ),
              _buildLoadingState(),
            ],
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC2185B), Color(0xFFE91E63)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC2185B).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                const Text(
                  'Centro de Reportes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _buildFechaSelector(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Análisis y estadísticas del negocio',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFechaSelector() {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _seleccionarFecha(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                formatoFecha.format(_fechaInicio),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const Text(' - ', style: TextStyle(color: Colors.white)),
          GestureDetector(
            onTap: () => _seleccionarFecha(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                formatoFecha.format(_fechaFin),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _cargarTodosLosReportes,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar reportes',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFC2185B),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFFC2185B),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
          Tab(icon: Icon(Icons.shopping_cart_rounded), text: 'Ventas'),
          Tab(icon: Icon(Icons.inventory_rounded), text: 'Inventario'),
          Tab(icon: Icon(Icons.account_balance_rounded), text: 'Financiero'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFC2185B), strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Cargando reportes...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          _buildResumenGeneral(),
          const SizedBox(height: 24),

          // Métricas principales
          _buildMetricasPrincipales(),
          const SizedBox(height: 24),

          // Productos más vendidos (vista compacta)
          _buildTopProductosCompacto(),
        ],
      ),
    );
  }

  Widget _buildVentasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con botón de exportar
          Row(
            children: [
              const Text(
                'Análisis de Ventas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _exportarCSV('ventas'),
                icon: const Icon(Icons.download),
                label: const Text('Exportar CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tarjetas de ventas
          if (_resumenVentas != null) ...[
            _buildTarjetasVentas(),
            const SizedBox(height: 24),

            // Ventas por día y método de pago
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildVentasPorDia()),
                const SizedBox(width: 16),
                Expanded(child: _buildVentasPorMetodoPago()),
              ],
            ),
          ] else
            _buildNoDataCard('ventas'),
        ],
      ),
    );
  }

  Widget _buildInventarioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Gestión de Inventario',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _exportarCSV('productos'),
                icon: const Icon(Icons.download),
                label: const Text('Exportar CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_reporteInventario != null)
            _buildReporteInventario()
          else
            _buildNoDataCard('inventario'),
        ],
      ),
    );
  }

  Widget _buildFinancieroTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Análisis Financiero',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          if (_resumenFinanciero != null)
            _buildResumenFinanciero()
          else
            _buildNoDataCard('financiero'),
        ],
      ),
    );
  }

  Widget _buildResumenGeneral() {
    if (_resumenVentas == null) return _buildNoDataCard('resumen general');

    final totalVentas = _resumenVentas!['totalVentas'] ?? 0;
    final ingresoTotal = _resumenVentas!['ingresoTotal'] ?? 0.0;
    final promedioVenta = _resumenVentas!['promedioVenta'] ?? 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFC2185B).withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2185B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Resumen del Período',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricaItem(
                    'Ventas Totales',
                    totalVentas.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricaItem(
                    'Ingresos',
                    '\$${ingresoTotal.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricaItem(
                    'Promedio/Venta',
                    '\$${promedioVenta.toStringAsFixed(2)}',
                    Icons.analytics,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaItem(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasPrincipales() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricaCard(
            'Estado del Inventario',
            _reporteInventario != null
                ? '${_reporteInventario!['totalProductos'] ?? 0} productos'
                : 'N/A',
            Icons.inventory,
            Colors.purple,
            _reporteInventario != null
                ? 'Stock bajo: ${_reporteInventario!['stockBajo'] ?? 0}'
                : '',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricaCard(
            'Productos Activos',
            _productosMasVendidos != null
                ? '${_productosMasVendidos!.length} productos'
                : 'N/A',
            Icons.trending_up,
            Colors.teal,
            'Con ventas en el período',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricaCard(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    String subtitulo,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitulo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductosCompacto() {
    if (_productosMasVendidos == null || _productosMasVendidos!.isEmpty) {
      return _buildNoDataCard('productos más vendidos');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 12),
                Text(
                  'Top Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._productosMasVendidos!.take(5).map((item) {
              final producto = item['producto'] as Producto;
              final cantidad = item['cantidadVendida'] as int;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2185B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.icecream,
                        color: Color(0xFFC2185B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$cantidad unidades vendidas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${_productosMasVendidos!.indexOf(item) + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetasVentas() {
    return Row(
      children: [
        Expanded(
          child: _buildTarjetaEstadistica(
            'Total de Ventas',
            '${_resumenVentas!['totalVentas']}',
            Icons.shopping_cart_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTarjetaEstadistica(
            'Ingresos Totales',
            '\$${_resumenVentas!['ingresoTotal'].toStringAsFixed(2)}',
            Icons.attach_money_rounded,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTarjetaEstadistica(
            'Ticket Promedio',
            '\$${_resumenVentas!['promedioVenta'].toStringAsFixed(2)}',
            Icons.trending_up_rounded,
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              valor,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVentasPorDia() {
    final ventasPorDia =
        _resumenVentas!['ventasPorDia'] as Map<String, dynamic>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFFC2185B), size: 20),
                SizedBox(width: 8),
                Text(
                  'Ventas por Día',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...ventasPorDia.entries.map((entry) {
              final fecha = DateFormat(
                'dd/MM/yyyy',
              ).format(DateTime.parse(entry.key));
              final cantidad = entry.value['cantidad'];
              final total = entry.value['total'];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fecha,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '$cantidad ventas • \$${total.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVentasPorMetodoPago() {
    final ventasPorMetodo =
        _resumenVentas!['ventasPorMetodoPago'] as Map<String, dynamic>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Color(0xFFC2185B), size: 20),
                SizedBox(width: 8),
                Text(
                  'Métodos de Pago',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...ventasPorMetodo.entries.map((entry) {
              final metodo = entry.key;
              final cantidad = entry.value['cantidad'];
              final total = entry.value['total'];

              IconData icono;
              Color color;
              switch (metodo.toLowerCase()) {
                case 'efectivo':
                  icono = Icons.money;
                  color = Colors.green;
                  break;
                case 'tarjeta':
                  icono = Icons.credit_card;
                  color = Colors.blue;
                  break;
                default:
                  icono = Icons.payment;
                  color = Colors.grey;
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(icono, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        metodo,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '$cantidad • \$${total.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteInventario() {
    final totalProductos = _reporteInventario!['totalProductos'] ?? 0;
    final stockBajo = _reporteInventario!['stockBajo'] ?? 0;
    final sinStock = _reporteInventario!['sinStock'] ?? 0;
    final valorTotal = _reporteInventario!['valorTotal'] ?? 0.0;

    return Column(
      children: [
        // Métricas de inventario
        Row(
          children: [
            Expanded(
              child: _buildTarjetaEstadistica(
                'Total Productos',
                totalProductos.toString(),
                Icons.inventory_rounded,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTarjetaEstadistica(
                'Stock Bajo',
                stockBajo.toString(),
                Icons.warning_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTarjetaEstadistica(
                'Sin Stock',
                sinStock.toString(),
                Icons.error_rounded,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Valor total del inventario
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.monetization_on, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor Total del Inventario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${valorTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenFinanciero() {
    final totalVentas = _resumenFinanciero!['totalVentas'] ?? 0.0;
    final margenBruto = _resumenFinanciero!['margenBruto'] ?? 0.0;
    final crecimiento = _resumenFinanciero!['crecimiento'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTarjetaEstadistica(
                'Ingresos del Período',
                '\$${totalVentas.toStringAsFixed(2)}',
                Icons.trending_up_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTarjetaEstadistica(
                'Margen Bruto',
                '${margenBruto.toStringAsFixed(1)}%',
                Icons.percent_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTarjetaEstadistica(
                'Crecimiento',
                '${crecimiento > 0 ? '+' : ''}${crecimiento.toStringAsFixed(1)}%',
                crecimiento >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                crecimiento >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoDataCard(String tipo) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay datos de $tipo disponibles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los datos aparecerán aquí cuando haya información disponible',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
