import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../models/categoria_producto.dart';
import '../services/producto_service.dart';

class ProductoDetailPanel extends StatefulWidget {
  final Producto producto;
  final CategoriaProducto categoria;
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
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto.nombre);
    _precioController = TextEditingController(text: widget.producto.precio.toString());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
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
    return size.width >= 600 ? 500.0 : size.width * 0.92;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: _panelWidth,
          margin: const EdgeInsets.all(32),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header con icono y botón de cerrar
                  Stack(
                    children: [
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFC2185B).withOpacity(0.1),
                              Colors.grey[50]!,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.icecream_rounded,
                            size: 80,
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
                        // Nombre del producto
                        TextFormField(
                          controller: _nombreController,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Nombre del producto',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Color(0xFFC2185B),
                            ),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'El nombre es requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Categoría (no editable)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC2185B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.category_outlined,
                                color: Color(0xFFC2185B),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.categoria.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFC2185B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Precio
                        TextFormField(
                          controller: _precioController,
                          decoration: InputDecoration(
                            labelText: 'Precio',
                            prefixText: '\$',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(
                              Icons.attach_money,
                              color: Color(0xFFC2185B),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 24),

                        // Mensaje de error si existe
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Botón de guardar
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _guardarCambios,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC2185B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                : const Text(
                                    'Guardar cambios',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
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
  }
}
