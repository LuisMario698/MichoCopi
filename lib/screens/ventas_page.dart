import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/nueva_venta_modal.dart';
import '../services/venta_service.dart';
import '../models/venta.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  List<Venta> _ventas = [];
  bool _isLoading = true;
  String _filtroFechaSeleccionado = 'Todos';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }
  Future<void> _cargarVentas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await VentaService.obtenerVentas();

      if (resultado['success']) {
        setState(() {
          _ventas = resultado['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _ventas = [];
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar ventas: ${resultado['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _ventas = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ventas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarModalNuevaVenta(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const NuevaVentaModal();
      },
    ).then((resultado) {
      // Si se procesó una venta exitosamente, recargar la lista
      if (resultado == true) {
        _cargarVentas();
      }
    });
  }
  List<Venta> get _ventasFiltradas {
    return _ventas.where((venta) {
      final matchesSearch = _searchQuery.isEmpty ||
          venta.id.toString().contains(_searchQuery) ||
          venta.total.toString().contains(_searchQuery);
      return matchesSearch;
    }).toList();
  }
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Ventas',
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            _mostrarModalNuevaVenta(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Nueva Venta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC2185B),
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: Column(
        children: [
          // Filtros y búsqueda
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar por cliente o ID de venta...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _filtroFechaSeleccionado,
                    items: ['Todos', 'Hoy', 'Esta semana', 'Este mes']
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filtroFechaSeleccionado = value;
                        });
                        _cargarVentas();
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _cargarVentas,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de ventas
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ID Venta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Cliente',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Fecha',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Estado',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFC2185B),
                            ),
                          )
                        : _ventasFiltradas.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay ventas disponibles',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _ventasFiltradas.length,
                                itemBuilder: (context, index) {
                                  final venta = _ventasFiltradas[index];
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey[200]!),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text('#${venta.id}'),
                                        ),                                        Expanded(
                                          flex: 3,
                                          child: Text('Cliente General'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '\$${venta.total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(_formatearFecha(venta.fecha)),
                                        ),                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Completada',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
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
        ],
      ),
    );
  }
}