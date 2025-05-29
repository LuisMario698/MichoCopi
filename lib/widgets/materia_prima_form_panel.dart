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

class _MateriaPrimaFormPanelState extends State<MateriaPrimaFormPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _stockController = TextEditingController();
  final _precioController = TextEditingController();

  List<CategoriaMp> _categorias = [];
  int? _categoriaSeleccionada;
  bool _seVende = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _nombreExiste = false;
  bool _validandoNombre = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _cargarDatos();
    _inicializarFormulario();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    _stockController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _inicializarFormulario() {
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

  Future<void> _cerrarPanel() async {
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final categorias = await CategoriaMpService().obtenerTodas();
      setState(() {
        _categorias = categorias;
        _isLoadingData = false;
      });
    } catch (e) {
      print('Error cargando categorías: $e');
      setState(() {
        _isLoadingData = false;
      });
      _mostrarSnackBar('Error al cargar las categorías', true);
    }
  }

  Future<void> _validarNombreMateria(String nombre) async {
    if (nombre.trim().isEmpty) {
      setState(() {
        _nombreExiste = false;
        _validandoNombre = false;
      });
      return;
    }

    setState(() {
      _validandoNombre = true;
    });

    try {
      // Aquí puedes implementar la validación de nombre si el servicio lo permite
      // Por ahora solo simularemos la validación
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _nombreExiste = false; // Cambiar según la lógica de validación real
          _validandoNombre = false;
        });
      }
    } catch (e) {
      print('Error validando nombre: $e');
      if (mounted) {
        setState(() {
          _nombreExiste = false;
          _validandoNombre = false;
        });
      }
    }
  }

  Future<void> _guardarMateriaPrima() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final materia = MateriaPrima(
        id: widget.materiaPrima?.id,
        nombre: _nombreController.text.trim(),
        idCategoriaMp: _categoriaSeleccionada!,
        stock: int.parse(_stockController.text),
        fechaCreacion: widget.materiaPrima?.fechaCreacion ?? DateTime.now(),
        seVende: _seVende,
        siVendePrecio: _seVende ? double.parse(_precioController.text) : null,
      );

      if (widget.materiaPrima == null) {
        await MateriaPrimaService().crear(materia);
        _mostrarSnackBar('Materia prima agregada exitosamente', false);
      } else {
        await MateriaPrimaService().actualizar(materia);
        _mostrarSnackBar('Materia prima actualizada exitosamente', false);
      }

      widget.onMateriaPrimaCreated(true);
      await _cerrarPanel();
    } catch (e) {
      print('Error al guardar: $e');
      _mostrarSnackBar('Error al guardar la materia prima', true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarSnackBar(String mensaje, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _stockController.clear();
    _precioController.clear();
    setState(() {
      _categoriaSeleccionada = null;
      _seVende = false;
      _nombreExiste = false;
      _validandoNombre = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFC2185B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.materiaPrima == null
                                ? 'Nueva Materia Prima'
                                : 'Editar Materia Prima',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _cerrarPanel,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: _isLoadingData
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFFC2185B),
                                ),
                                SizedBox(height: 16),
                                Text('Cargando datos...'),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Información básica
                                  Card(
                                    elevation: 0,
                                    color: Colors.grey[50],
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Color(0xFFC2185B),
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Información Básica',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: _nombreController,
                                            decoration: InputDecoration(
                                              labelText: 'Nombre de la materia prima *',
                                              prefixIcon: const Icon(
                                                Icons.inventory_2,
                                                color: Color(0xFFC2185B),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              helperText: 'El nombre debe ser único',
                                              suffixIcon: _validandoNombre
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: Padding(
                                                        padding: EdgeInsets.all(8.0),
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    )
                                                  : _nombreExiste
                                                      ? const Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                        )
                                                      : _nombreController.text.isNotEmpty
                                                          ? const Icon(
                                                              Icons.check_circle,
                                                              color: Colors.green,
                                                            )
                                                          : null,
                                            ),
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'El nombre es obligatorio';
                                              }
                                              if (value.trim().length < 2) {
                                                return 'El nombre debe tener al menos 2 caracteres';
                                              }
                                              if (_nombreExiste) {
                                                return 'Ya existe una materia prima con este nombre';
                                              }
                                              return null;
                                            },
                                            onChanged: (value) {
                                              if (value.trim().length >= 2) {
                                                _validarNombreMateria(value.trim());
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          DropdownButtonFormField<int>(
                                            value: _categoriaSeleccionada,
                                            decoration: InputDecoration(
                                              labelText: 'Categoría *',
                                              prefixIcon: const Icon(
                                                Icons.category,
                                                color: Color(0xFFC2185B),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            items: _categorias
                                                .where((categoria) => categoria.id != null)
                                                .map((categoria) {
                                              return DropdownMenuItem<int>(
                                                value: categoria.id!,
                                                child: Text(categoria.nombre),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _categoriaSeleccionada = value;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'Selecciona una categoría';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: _stockController,
                                            decoration: InputDecoration(
                                              labelText: 'Stock inicial *',
                                              prefixIcon: const Icon(
                                                Icons.inventory,
                                                color: Color(0xFFC2185B),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              helperText: 'Cantidad disponible en inventario',
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly
                                            ],
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
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Información de venta
                                  Card(
                                    elevation: 0,
                                    color: Colors.grey[50],
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.sell,
                                                color: Color(0xFFC2185B),
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Información de Venta',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          SwitchListTile(
                                            title: const Text('¿Se vende al público?'),
                                            subtitle: const Text(
                                              'Indica si esta materia prima también se vende como producto',
                                            ),
                                            value: _seVende,
                                            activeColor: const Color(0xFFC2185B),
                                            onChanged: (value) {
                                              setState(() {
                                                _seVende = value;
                                                if (!value) {
                                                  _precioController.clear();
                                                }
                                              });
                                            },
                                          ),
                                          if (_seVende) ...[
                                            const SizedBox(height: 16),
                                            TextFormField(
                                              controller: _precioController,
                                              decoration: InputDecoration(
                                                labelText: 'Precio de venta *',
                                                prefixIcon: const Icon(
                                                  Icons.attach_money,
                                                  color: Color(0xFFC2185B),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                helperText: 'Precio por unidad de venta',
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
                                ],
                              ),
                            ),
                          ),
                  ),
                  // Footer con botones
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : _limpiarFormulario,
                          child: const Text('Limpiar'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _isLoading ? null : _cerrarPanel,
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _guardarMateriaPrima,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC2185B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(widget.materiaPrima == null ? 'Agregar' : 'Actualizar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
