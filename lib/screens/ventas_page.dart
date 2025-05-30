import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/nueva_venta_modal.dart';
import '../services/venta_service.dart';
import '../services/tipo_cambio_service.dart';
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
  double _tipoCambio = 17.50; // Valor por defecto
  bool _cargandoTipoCambio = false;
  @override
  void initState() {
    super.initState();
    _cargarVentas();
    _cargarTipoCambio();
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
      final matchesSearch =
          _searchQuery.isEmpty ||
          venta.id.toString().contains(_searchQuery) ||
          venta.total.toString().contains(_searchQuery);
      return matchesSearch;
    }).toList();
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  // Cargar el tipo de cambio actual
  Future<void> _cargarTipoCambio() async {
    setState(() {
      _cargandoTipoCambio = true;
    });

    try {
      final resultado = await TipoCambioService.obtenerTipoCambio();
      if (resultado['success']) {
        setState(() {
          _tipoCambio = resultado['data'];
        });
      }
    } catch (e) {
      // Mantener el valor por defecto en caso de error
    } finally {
      setState(() {
        _cargandoTipoCambio = false;
      });
    }
  }

  // Mostrar diálogo para editar el tipo de cambio
  void _mostrarEditarTipoCambio() {
    final controller = TextEditingController(text: _tipoCambio.toString());

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Tipo de Cambio'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor del dólar en pesos',
                hintText: 'Ejemplo: 17.50',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final nuevoValor = double.tryParse(controller.text) ?? 0;
                    if (nuevoValor <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Valor inválido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final resultado =
                        await TipoCambioService.actualizarTipoCambio(
                          nuevoValor,
                        );
                    if (resultado['success']) {
                      setState(() {
                        _tipoCambio = nuevoValor;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tipo de cambio actualizado correctamente',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${resultado['message']}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  // Widget para mostrar el tipo de cambio
  Widget _buildTipoCambioWidget() {
    return InkWell(
      onTap: _mostrarEditarTipoCambio,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.currency_exchange, color: Colors.blue, size: 18),
            const SizedBox(width: 8),
            _cargandoTipoCambio
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Text(
                  'Dólar: \$${_tipoCambio.toStringAsFixed(2)} MXN',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Ventas',
      actions: [
        _buildTipoCambioWidget(),
        const SizedBox(width: 16),
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
                    items:
                        ['Todos', 'Hoy', 'Esta semana', 'Este mes']
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
                    child:
                        _isLoading
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
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text('#${venta.id}'),
                                      ),
                                      Expanded(
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
                                        child: Text(
                                          _formatearFecha(venta.fecha),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
