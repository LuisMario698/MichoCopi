import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/materia_prima.dart';
import '../models/categoria_mp.dart';
import '../services/categoria_mp_service.dart';
import '../services/materia_prima_service.dart';

class MateriaPrimaFormPanel extends StatefulWidget {
  final MateriaPrima? materiaPrima;
  final VoidCallback onClose;
  final Function(bool) onMateriaPrimaCreated;

  const MateriaPrimaFormPanel({
    super.key,
    this.materiaPrima,
    required this.onClose,
    required this.onMateriaPrimaCreated,
  });

  @override
  State<MateriaPrimaFormPanel> createState() => _MateriaPrimaFormPanelState();
}

class _MateriaPrimaFormPanelState extends State<MateriaPrimaFormPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _stockController = TextEditingController();
  final _precioController = TextEditingController();

  int? _categoriaSeleccionada;
  bool _seVende = false;
  List<CategoriaMp> _categorias = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    if (widget.materiaPrima != null) {
      _nombreController.text = widget.materiaPrima!.nombre;
      _stockController.text = widget.materiaPrima!.stock.toString();
      _categoriaSeleccionada = widget.materiaPrima!.idCategoriaMp;
      _seVende = widget.materiaPrima!.seVende;
      if (widget.materiaPrima!.siVendePrecio != null) {
        _precioController.text = widget.materiaPrima!.siVendePrecio.toString();
      }
    }
  }

  Future<void> _cargarCategorias() async {
    try {
      setState(() => _isLoading = true);
      _categorias = await CategoriaMpService().obtenerTodas();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final materia = MateriaPrima(
        id: widget.materiaPrima?.id,
        nombre: _nombreController.text,
        idCategoriaMp: _categoriaSeleccionada!,
        stock: int.parse(_stockController.text),
        fechaCreacion: widget.materiaPrima?.fechaCreacion ?? DateTime.now(),
        seVende: _seVende,
        siVendePrecio: _seVende ? double.parse(_precioController.text) : null,
      );

      if (widget.materiaPrima == null) {
        await MateriaPrimaService().crear(materia);
      } else {
        await MateriaPrimaService().actualizar(materia);
      }

      if (mounted) {
        widget.onMateriaPrimaCreated(true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.materiaPrima == null
            ? 'Nueva Materia Prima'
            : 'Editar Materia Prima',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value:
                    _categorias.any((c) => c.id == _categoriaSeleccionada)
                        ? _categoriaSeleccionada
                        : null,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items:
                    _categorias.map((categoria) {
                      return DropdownMenuItem(
                        value: categoria.id,
                        child: Text(categoria.nombre),
                      );
                    }).toList(),
                onChanged:
                    _isLoading
                        ? null
                        : (value) {
                          setState(() => _categoriaSeleccionada = value);
                        },
                validator: (value) {
                  if (value == null) {
                    return 'Debe seleccionar una categoría';
                  }
                  return null;
                },
                disabledHint:
                    _isLoading
                        ? const Text('Cargando categorías...')
                        : (_categorias.isEmpty
                            ? const Text('No hay categorías')
                            : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Inicial',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El stock es requerido';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null || stock < 0) {
                    return 'El stock debe ser un número válido mayor o igual a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('¿Se vende?'),
                value: _seVende,
                onChanged: (value) {
                  setState(() => _seVende = value ?? false);
                },
              ),
              if (_seVende) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio de Venta',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (!_seVende) return null;
                    if (value == null || value.isEmpty) {
                      return 'El precio es requerido si la materia prima se vende';
                    }
                    final precio = double.tryParse(value);
                    if (precio == null || precio <= 0) {
                      return 'El precio debe ser un número válido mayor a 0';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _stockController.dispose();
    _precioController.dispose();
    super.dispose();
  }
}
