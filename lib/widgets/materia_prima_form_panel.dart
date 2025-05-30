import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
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

  List<CategoriaMp> _categorias = [];
  int? _categoriaSeleccionada;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _nombreTouched = false;
  bool _stockTouched = false;
  bool _categoriaTouched = false;

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

    _nombreController.addListener(() {
      if (_nombreController.text.isNotEmpty) {
        setState(() => _nombreTouched = true);
      }
    });

    _stockController.addListener(() {
      if (_stockController.text.isNotEmpty) {
        setState(() => _stockTouched = true);
      }
    });

    _cargarDatos();
    _inicializarFormulario();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _inicializarFormulario() {
    if (widget.materiaPrima != null) {
      _nombreController.text = widget.materiaPrima!.nombre;
      _stockController.text = widget.materiaPrima!.stock.toString();
      _categoriaSeleccionada = widget.materiaPrima!.idCategoriaMp;
    }
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
        seVende: false,
        siVendePrecio: null,
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

  Future<void> _cerrarPanel() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            children: [
              // Fondo con blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
              ),
              // Dialog
              Center(
                child: Transform.scale(
                  scale: _animation.value,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.35,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFC2185B),
                                  const Color(0xFFC2185B).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(28),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.materiaPrima == null
                                            ? 'Nueva Materia Prima'
                                            : 'Editar Materia Prima',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ingrese los datos de la materia prima',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _cerrarPanel,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Content
                          Expanded(
                            child:
                                _isLoadingData
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFC2185B,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child:
                                                const CircularProgressIndicator(
                                                  color: Color(0xFFC2185B),
                                                  strokeWidth: 3,
                                                ),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            'Cargando datos...',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Espere un momento por favor',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : SingleChildScrollView(
                                      padding: const EdgeInsets.all(28),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Nombre
                                            TextFormField(
                                              controller: _nombreController,
                                              onTap:
                                                  () => setState(
                                                    () => _nombreTouched = true,
                                                  ),
                                              decoration: InputDecoration(
                                                labelText: 'Nombre *',
                                                hintText: 'Ej: Harina de trigo',
                                                prefixIcon: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _nombreTouched
                                                            ? const Color(
                                                              0xFFC2185B,
                                                            ).withOpacity(0.1)
                                                            : Colors
                                                                .transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.inventory_2_outlined,
                                                    color: const Color(
                                                      0xFFC2185B,
                                                    ),
                                                  ),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFC2185B,
                                                            ),
                                                            width: 2,
                                                          ),
                                                    ),
                                                floatingLabelStyle:
                                                    const TextStyle(
                                                      color: Color(0xFFC2185B),
                                                    ),
                                                helperText:
                                                    'Ingrese el nombre de la materia prima',
                                                helperStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'El nombre es requerido';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 24),

                                            // Categoría
                                            DropdownButtonFormField<int>(
                                              value: _categoriaSeleccionada,
                                              onTap:
                                                  () => setState(
                                                    () =>
                                                        _categoriaTouched =
                                                            true,
                                                  ),
                                              decoration: InputDecoration(
                                                labelText: 'Categoría *',
                                                prefixIcon: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _categoriaTouched
                                                            ? const Color(
                                                              0xFFC2185B,
                                                            ).withOpacity(0.1)
                                                            : Colors
                                                                .transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.category_outlined,
                                                    color: Color(0xFFC2185B),
                                                  ),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                                helperText:
                                                    'Seleccione la categoría de la materia prima',
                                                helperStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFC2185B,
                                                            ),
                                                            width: 2,
                                                          ),
                                                    ),
                                                floatingLabelStyle:
                                                    const TextStyle(
                                                      color: Color(0xFFC2185B),
                                                    ),
                                              ),
                                              items:
                                                  _categorias.map((categoria) {
                                                    return DropdownMenuItem(
                                                      value: categoria.id,
                                                      child: Text(
                                                        categoria.nombre,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _categoriaSeleccionada =
                                                      value;
                                                });
                                              },
                                              validator: (value) {
                                                if (value == null) {
                                                  return 'Seleccione una categoría';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 24),

                                            // Stock
                                            TextFormField(
                                              controller: _stockController,
                                              onTap:
                                                  () => setState(
                                                    () => _stockTouched = true,
                                                  ),
                                              decoration: InputDecoration(
                                                labelText: 'Stock inicial *',
                                                hintText: 'Ej: 100',
                                                prefixIcon: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _stockTouched
                                                            ? const Color(
                                                              0xFFC2185B,
                                                            ).withOpacity(0.1)
                                                            : Colors
                                                                .transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.inventory_outlined,
                                                    color: Color(0xFFC2185B),
                                                  ),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                                helperText:
                                                    'Ingrese la cantidad inicial en inventario',
                                                helperStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFC2185B,
                                                            ),
                                                            width: 2,
                                                          ),
                                                    ),
                                                floatingLabelStyle:
                                                    const TextStyle(
                                                      color: Color(0xFFC2185B),
                                                    ),
                                                suffixText: ' unidades',
                                                suffixStyle: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'El stock es requerido';
                                                }
                                                if (int.tryParse(value) ==
                                                        null ||
                                                    int.parse(value) < 0) {
                                                  return 'Ingrese un número válido';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                          ),
                          // Buttons
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border(
                                top: BorderSide(color: Colors.grey[200]!),
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(28),
                                bottomRight: Radius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Botón Cancelar con animación hover
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _cerrarPanel,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.close,
                                          size: 20,
                                          color: Colors.grey[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Cancelar',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Botón Guardar con animación y gradiente
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFFC2185B),
                                          const Color(
                                            0xFFC2185B,
                                          ).withOpacity(0.8),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFC2185B,
                                          ).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: FilledButton.icon(
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : _guardarMateriaPrima,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      icon:
                                          _isLoading
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                              : const Icon(Icons.save_outlined),
                                      label: Text(
                                        widget.materiaPrima == null
                                            ? 'Crear Materia Prima'
                                            : 'Guardar Cambios',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
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
            ],
          );
        },
      ),
    );
  }
}
