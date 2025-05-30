import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/reportes_service.dart';
import '../services/producto_service.dart';
import '../models/producto.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _cargando = false; // Variables para el rango de fechas en ventas
  DateTime _fechaInicioVentas = DateTime.now().subtract(
    const Duration(days: 7),
  );
  DateTime _fechaFinVentas = DateTime.now();
  final DateFormat formatoFecha = DateFormat('dd/MM/yyyy'); // Datos de reportes
  Map<String, dynamic>? _resumenVentas;
  List<Map<String, dynamic>>? _productosMasVendidos;
  Map<String, dynamic>? _reporteInventario;
  List<Map<String, dynamic>>? _categorias;
  List<dynamic>? _productos;

  // Variables para barras de búsqueda
  String _busquedaCategorias = '';
  String _busquedaProductos = '';

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
    if (!mounted) return;
    
    setState(() {
      _cargando = true;
    });

    try {
      // Usar los últimos 30 días como período fijo para productos e inventario
      final fechaFin = DateTime.now();
      final fechaInicio = fechaFin.subtract(
        const Duration(days: 30),
      );// Para ventas, usar el rango de fechas seleccionado
      final fechaInicioVentas = DateTime(
        _fechaInicioVentas.year,
        _fechaInicioVentas.month,
        _fechaInicioVentas.day,
      );
      final fechaFinVentas = DateTime(
        _fechaFinVentas.year,
        _fechaFinVentas.month,
        _fechaFinVentas.day,
        23,
        59,
        59,
        999,
      );
      final futures = await Future.wait([
        ReportesService.obtenerResumenVentas(
          fechaInicio: fechaInicioVentas,
          fechaFin: fechaFinVentas,
        ),
        ReportesService.obtenerProductosMasVendidos(
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        ),
        ReportesService.obtenerReporteInventario(),
        ProductoService.obtenerCategorias(),
        ProductoService.obtenerProductos(),
      ]);
      setState(() {
        if (futures[0]['success']) _resumenVentas = futures[0]['data'];
        if (futures[1]['success'])
          _productosMasVendidos = List<Map<String, dynamic>>.from(
            futures[1]['data'],
          );
        if (futures[2]['success']) _reporteInventario = futures[2]['data'];
        if (futures[3]['success']) {
          // Convertir la lista de CategoriaProducto a Map<String, dynamic>
          _categorias =
              (futures[3]['data'] as List).map((categoria) {
                return {
                  'id': categoria.id,
                  'nombre': categoria.nombre,
                  'conCaducidad': categoria.conCaducidad,
                };
              }).toList();
        }
        if (futures[4]['success']) _productos = futures[4]['data'];
      });
    } catch (e) {
      _mostrarError('Error al cargar reportes: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  // Cargar solo los datos de ventas with el rango de fechas seleccionado
  Future<void> _cargarDatosVentas() async {
    setState(() {
      _cargando = true;
    });

    try {
      // Usar el rango de fechas seleccionado
      final fechaInicio = DateTime(
        _fechaInicioVentas.year,
        _fechaInicioVentas.month,
        _fechaInicioVentas.day,
      );
      final fechaFin = DateTime(
        _fechaFinVentas.year,
        _fechaFinVentas.month,
        _fechaFinVentas.day,
        23,
        59,
        59,
        999,
      );

      final resultado = await ReportesService.obtenerResumenVentas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      setState(() {
        if (resultado['success']) _resumenVentas = resultado['data'];
      });
    } catch (e) {
      _mostrarError('Error al cargar datos de ventas: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  } // Seleccionar rango de fechas para el filtro de ventas

  Future<void> _seleccionarFechaVentas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _fechaInicioVentas,
        end: _fechaFinVentas,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFFC2185B)),
          ),
          child: Center(
            child: Container(
              width: 500,
              height: 400,
              /*decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC2185B).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),*/
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (rango != null) {
      setState(() {
        _fechaInicioVentas = rango.start;
        _fechaFinVentas = rango.end;
      });
      _cargarDatosVentas();
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

  Future<void> _exportarCSV(String tipoReporte) async {
    setState(() {
      _cargando = true;
    });

    try {
      String csvData = '';
      String nombreArchivo = '';
      switch (tipoReporte) {
        case 'ventas':
          // Usar el rango de fechas seleccionado por el usuario
          final fechaInicio = DateTime(
            _fechaInicioVentas.year,
            _fechaInicioVentas.month,
            _fechaInicioVentas.day,
          );
          final fechaFin = DateTime(
            _fechaFinVentas.year,
            _fechaFinVentas.month,
            _fechaFinVentas.day,
            23,
            59,
            59,
            999,
          );

          final result = await ReportesService.exportarVentasCSV(
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
          );
          if (result['success']) {
            csvData = result['data'];
            nombreArchivo =
                'ventas_${DateFormat('yyyy-MM-dd').format(_fechaInicioVentas)}_${DateFormat('yyyy-MM-dd').format(_fechaFinVentas)}.csv';
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
                    _buildVentasTab(),
                    _buildProductosTab(),
                    _buildMateriaPrimaTab(),
                    _buildCortesTab(),
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
          Tab(icon: Icon(Icons.shopping_cart_rounded), text: 'Ventas'),
          Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Productos'),
          Tab(icon: Icon(Icons.category_rounded), text: 'Materia Prima'),
          Tab(icon: Icon(Icons.content_cut_rounded), text: 'Cortes'),
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
              // Date picker específico para ventas (un solo día)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC2185B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFC2185B).withOpacity(0.3),
                  ),
                ),
                child: GestureDetector(
                  onTap: _seleccionarFechaVentas,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event,
                        color: Color(0xFFC2185B),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${formatoFecha.format(_fechaInicioVentas)} - ${formatoFecha.format(_fechaFinVentas)}',
                        style: const TextStyle(
                          color: Color(0xFFC2185B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFC2185B),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                Expanded(flex: 4, child: _buildVentasPorDia()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildVentasPorMetodoPago()),
              ],
            ),
          ] else
            _buildNoDataCard('ventas'),
        ],
      ),
    );
  }

  Widget _buildProductosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Análisis de Productos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),

              // Date picker específico para ventas (un solo día)
              const Spacer(), // Date picker específico para ventas (rango de fechas)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC2185B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFC2185B).withOpacity(0.3),
                  ),
                ),
                child: GestureDetector(
                  onTap: _seleccionarFechaVentas,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event,
                        color: Color(0xFFC2185B),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${formatoFecha.format(_fechaInicioVentas)} - ${formatoFecha.format(_fechaFinVentas)}',
                        style: const TextStyle(
                          color: Color(0xFFC2185B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFC2185B),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
          if (_productosMasVendidos != null &&
              _productosMasVendidos!.isNotEmpty) ...[
            _buildTopProductosCompacto(),
            const SizedBox(height: 24),
            SizedBox(
              height: 600, // Alto definido para las tablas
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTablaCategorias()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTablaProductos()),
                ],
              ),
            ),
          ] else
            _buildNoDataCard('productos'),
        ],
      ),
    );
  }

  Widget _buildMateriaPrimaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Inventario de Materia Prima',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Date picker específico para ventas (rango de fechas)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC2185B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFC2185B).withOpacity(0.3),
                  ),
                ),
                child: GestureDetector(
                  onTap: _seleccionarFechaVentas,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event,
                        color: Color(0xFFC2185B),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${formatoFecha.format(_fechaInicioVentas)} - ${formatoFecha.format(_fechaFinVentas)}',
                        style: const TextStyle(
                          color: Color(0xFFC2185B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFC2185B),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _exportarCSV('materia-prima'),
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
          if (_reporteInventario != null) ...[
            _buildReporteInventario(),
          ] else
            _buildNoDataCard('materia prima'),
        ],
      ),
    );
  }

  Widget _buildCortesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Cortes de Inventario',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoCorte(),
                icon: const Icon(Icons.content_cut),
                label: const Text('Nuevo Corte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNoDataCard('cortes de inventario'),
        ],
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
            ..._productosMasVendidos!.take(3).map((item) {
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
            // Header con título y filtro de fecha
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFC2185B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
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

  void _mostrarDialogoCorte() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nuevo Corte de Inventario'),
            content: const Text(
              'Funcionalidad de cortes de inventario estará disponible próximamente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }

  Widget _buildTablaCategorias() {
    if (_categorias == null || _categorias!.isEmpty) {
      return _buildNoDataCard('categorías');
    }

    // Filtrar categorías según el término de búsqueda
    final categoriasFiltradas =
        _categorias!.where((categoria) {
          final nombre = (categoria['nombre'] ?? '').toString().toLowerCase();
          return nombre.contains(_busquedaCategorias.toLowerCase());
        }).toList();

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
                Icon(Icons.category, color: Color(0xFFC2185B), size: 24),
                SizedBox(width: 12),
                Text(
                  'Categorías de Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra de búsqueda para categorías
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar categorías...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFC2185B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFC2185B),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _busquedaCategorias = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Contenedor con altura fija y scroll para la tabla
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Header de la tabla (fijo)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2185B).withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Nombre',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2185B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Contenido scrolleable
                    Expanded(
                      child: ListView.builder(
                        itemCount: categoriasFiltradas.length,
                        itemBuilder: (context, index) {
                          final categoria = categoriasFiltradas[index];
                          final nombre = categoria['nombre'] ?? 'Sin nombre';
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mostrar contador de resultados
            if (_busquedaCategorias.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Mostrando ${categoriasFiltradas.length} de ${_categorias!.length} categorías',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTablaProductos() {
    if (_productos == null || _productos!.isEmpty) {
      return _buildNoDataCard('productos');
    }

    // Crear un mapa de categorías para obtener el nombre por ID
    final Map<int, String> categoriasMap = {};
    if (_categorias != null) {
      for (final categoria in _categorias!) {
        categoriasMap[categoria['id']] = categoria['nombre'] ?? 'Sin categoría';
      }
    }

    // Filtrar productos según el término de búsqueda
    final productosFiltrados =
        _productos!.where((productoData) {
          final producto =
              productoData is Producto
                  ? productoData
                  : Producto.fromJson(productoData as Map<String, dynamic>);

          final nombre = producto.nombre.toLowerCase();
          final categoria =
              categoriasMap[producto.idCategoriaProducto] ?? 'Sin categoría';
          final precio = producto.precio.toString();

          final busqueda = _busquedaProductos.toLowerCase();
          return nombre.contains(busqueda) ||
              categoria.toLowerCase().contains(busqueda) ||
              precio.contains(busqueda);
        }).toList();

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
                Icon(Icons.table_chart, color: Color(0xFFC2185B), size: 20),
                SizedBox(width: 8),
                Text(
                  'Lista de Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra de búsqueda para productos
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar productos por nombre, categoría o precio...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFC2185B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFC2185B),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _busquedaProductos = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Contenedor con altura fija y scroll para la tabla
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Header de la tabla (fijo)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2185B).withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Nombre',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2185B),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Precio',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2185B),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Categoría',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2185B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Contenido scrolleable
                    Expanded(
                      child: ListView.builder(
                        itemCount: productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final productoData = productosFiltrados[index];
                          final producto =
                              productoData is Producto
                                  ? productoData
                                  : Producto.fromJson(
                                    productoData as Map<String, dynamic>,
                                  );

                          final nombreCategoria =
                              categoriasMap[producto.idCategoriaProducto] ??
                              'Sin categoría';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    producto.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\$${producto.precio.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    nombreCategoria,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mostrar contador de resultados
            const SizedBox(height: 12),
            Text(
              _busquedaProductos.isNotEmpty
                  ? 'Mostrando ${productosFiltrados.length} productos encontrados'
                  : 'Mostrando ${productosFiltrados.length} de ${_productos!.length} productos',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
