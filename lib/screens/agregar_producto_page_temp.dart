import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../models/categoria_producto.dart';
import '../services/producto_service.dart';

class AgregarProductoPage extends StatefulWidget {
  const AgregarProductoPage({super.key});

  @override
  State<AgregarProductoPage> createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<AgregarProductoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  List<CategoriaProducto> _categorias = [];
  int? _categoriaSeleccionada;

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final categoriasResult = await ProductoService.obtenerCategorias();

      if (categoriasResult['success']) {
        setState(() {
          _categorias = List<CategoriaProducto>.from(categoriasResult['data']);
          _isLoadingData = false;
        });
      } else {
        // Datos de prueba en caso de error
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      // Datos de prueba en caso de error
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSeleccionada == null) {
      _mostrarSnackBar('Por favor selecciona una categoría', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final producto = Producto(
        nombre: _nombreController.text.trim(),
        precio: double.parse(_precioController.text),
        idCategoriaProducto: _categoriaSeleccionada!,
      );

      final result = await ProductoService.crearProducto(producto);

      if (result['success']) {
        _mostrarSnackBar('Producto agregado exitosamente');
        _limpiarFormulario();
      } else {
        _mostrarSnackBar(
          'Error al crear el producto: ${result['message']}',
          isError: true,
        );
      }
    } catch (e) {
      _mostrarSnackBar('Error inesperado: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _precioController.clear();
    setState(() {
      _categoriaSeleccionada = null;
    });
  }

  void _mostrarSnackBar(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
        backgroundColor: const Color(0xFFC2185B),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Campo Nombre
                              TextFormField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del producto *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa el nombre del producto';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16), // Campo Precio
                              TextFormField(
                                controller: _precioController,
                                decoration: const InputDecoration(
                                  labelText: 'Precio *',
                                  border: OutlineInputBorder(),
                                  prefixText: '\$ ',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa el precio';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Por favor ingresa un precio válido';
                                  }
                                  if (double.parse(value) <= 0) {
                                    return 'El precio debe ser mayor a 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Dropdown Categoría
                              DropdownButtonFormField<int>(
                                value: _categoriaSeleccionada,
                                decoration: const InputDecoration(
                                  labelText: 'Categoría *',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    _categorias
                                        .where(
                                          (categoria) => categoria.id != null,
                                        )
                                        .map(
                                          (categoria) => DropdownMenuItem<int>(
                                            value: categoria.id!,
                                            child: Row(
                                              children: [
                                                Text(categoria.nombre),
                                                if (categoria.conCaducidad) ...[
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.schedule,
                                                    size: 16,
                                                    color: Colors.orange[700],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _categoriaSeleccionada = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Por favor selecciona una categoría';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Botones
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _guardarProducto,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC2185B),
                                  foregroundColor: Colors.white,
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Text('Guardar Producto'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
