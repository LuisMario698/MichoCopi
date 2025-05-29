import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';

class ProductoDetailPanel extends StatefulWidget {
  final Producto producto;
  final Categoria categoria;
  final VoidCallback onClose;
  final Function(bool) onProductoUpdated;

  const ProductoDetailPanel({
    Key? key,
    required this.producto,
    required this.categoria,
    required this.onClose,
    required this.onProductoUpdated,
  }) : super(key: key);

  @override
  State<ProductoDetailPanel> createState() => _ProductoDetailPanelState();
}

class _ProductoDetailPanelState extends State<ProductoDetailPanel> {
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _stockController;
  DateTime? _caducidad;
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto.nombre);
    _precioController = TextEditingController(text: widget.producto.precio.toString());
    _stockController = TextEditingController(text: widget.producto.stock.toString());
    _caducidad = widget.producto.caducidad;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productoActualizado = widget.producto.copyWith(
        nombre: _nombreController.text,
        precio: double.parse(_precioController.text),
        stock: int.parse(_stockController.text),
        caducidad: _caducidad,
      );

      if (widget.producto.id == null) {
        setState(() {
          _errorMessage = 'Error: No se puede actualizar un producto sin ID';
        });
        return;
      }

      final result = await ProductoService.actualizarProducto(
        widget.producto.id!,
        productoActualizado,
      );
      
      if (result['success']) {
        widget.onProductoUpdated(true);
        widget.onClose();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error al actualizar el producto';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hacemos el panel más compacto para desktop
  double get _panelWidth {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 600;
    return isDesktop ? 500.0 : size.width * 0.92;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () => widget.onClose(),
        child: Container(
          color: Colors.black54,
          child: GestureDetector(
            onTap: () {}, // Prevent tap from propagating
            child: Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: _panelWidth,
                      ),
                      child: Card(
                        margin: const EdgeInsets.all(32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Iconos y botón de cerrar
                                Stack(
                                  children: [
                                    Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.icecream,
                                          size: 96,
                                          color: Color(0xFFC2185B),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: widget.onClose,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          elevation: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Contenido
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Contenedor de nombre y categoría
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextFormField(
                                            controller: _nombreController,
                                            decoration: const InputDecoration(
                                              labelText: 'Nombre',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.shopping_bag, color: Color(0xFFC2185B)),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            validator: (value) {
                                              if (value?.trim().isEmpty ?? true) {
                                                return 'El nombre es requerido';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              widget.categoria.nombre,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // Precio y Stock
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _precioController,
                                              decoration: InputDecoration(
                                                labelText: 'Precio',
                                                border: const OutlineInputBorder(),
                                                prefixText: '\$',
                                                filled: true,
                                                fillColor: const Color.fromARGB(255, 238, 97, 154).withOpacity(0.1),
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFC2185B),
                                                fontSize: 18,
                                              ),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                              ],
                                              validator: (value) {
                                                if (value?.isEmpty ?? true) {
                                                  return 'El precio es requerido';
                                                }
                                                final precio = double.tryParse(value!);
                                                if (precio == null || precio <= 0) {
                                                  return 'Ingrese un precio válido';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _stockController,
                                              decoration: const InputDecoration(
                                                labelText: 'Stock',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(Icons.inventory_2, color: Color(0xFFC2185B)),
                                              ),
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                              ],
                                              validator: (value) {
                                                if (value?.isEmpty ?? true) {
                                                  return 'El stock es requerido';
                                                }
                                                final stock = int.tryParse(value!);
                                                if (stock == null || stock < 0) {
                                                  return 'Ingrese un stock válido';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // Fecha de caducidad
                                      if (widget.categoria.conCaducidad) ...[
                                        const Divider(height: 32),
                                        InkWell(
                                          onTap: () async {
                                            final fecha = await showDatePicker(
                                              context: context,
                                              initialDate: _caducidad ?? DateTime.now(),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                            );
                                            if (fecha != null) {
                                              setState(() => _caducidad = fecha);
                                            }
                                          },
                                          child: Builder(
                                            builder: (context) {
                                              final Map<String, dynamic> estadoCaducidad;
                                              if (_caducidad == null) {
                                                estadoCaducidad = {
                                                  'color': Colors.grey[700],
                                                  'backgroundColor': Colors.grey[50],
                                                  'icon': Icons.calendar_today,
                                                  'mensaje': 'Sin fecha de caducidad',
                                                };
                                              } else {
                                                final diferencia = _caducidad!.difference(DateTime.now()).inDays;
                                                if (diferencia < 0) {
                                                  estadoCaducidad = {
                                                    'color': Colors.red[700],
                                                    'backgroundColor': Colors.red[50],
                                                    'icon': Icons.warning,
                                                    'mensaje': 'Vencido (${-diferencia}d)',
                                                  };
                                                } else if (diferencia <= 7) {
                                                  estadoCaducidad = {
                                                    'color': Colors.orange[700],
                                                    'backgroundColor': Colors.orange[50],
                                                    'icon': Icons.access_time,
                                                    'mensaje': diferencia == 0 ? 'Vence hoy' : '${diferencia}d restantes',
                                                  };
                                                } else {
                                                  estadoCaducidad = {
                                                    'color': Colors.green[700],
                                                    'backgroundColor': Colors.green[50],
                                                    'icon': Icons.check_circle_outline,
                                                    'mensaje': 'Vigente ($diferencia días)',
                                                  };
                                                }
                                              }

                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: estadoCaducidad['backgroundColor'],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      estadoCaducidad['icon'],
                                                      size: 20,
                                                      color: estadoCaducidad['color'],
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          estadoCaducidad['mensaje'],
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: estadoCaducidad['color'],
                                                          ),
                                                        ),
                                                        if (_caducidad != null)
                                                          Text(
                                                            '${_caducidad!.day}/${_caducidad!.month}/${_caducidad!.year}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: estadoCaducidad['color'],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const Spacer(),
                                                    if (_caducidad != null)
                                                      IconButton(
                                                        icon: const Icon(Icons.clear),
                                                        iconSize: 20,
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () {
                                                          setState(() => _caducidad = null);
                                                        },
                                                        color: estadoCaducidad['color'],
                                                      ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      // Mensaje de error
                                      if (_errorMessage != null) ...[
                                        Text(
                                          _errorMessage!,
                                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                      // Botón de guardar
                                      ElevatedButton(
                                        onPressed: _isLoading ? null : _guardarCambios,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFC2185B),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Text('Guardar cambios',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
