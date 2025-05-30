import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/proveedor.dart';
import '../models/categoria_proveedor.dart';
import '../services/proveedor_service.dart';
import '../services/categoria_proveedor_service.dart';

class ProveedorFormPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Function(bool) onProveedorCreated;
  final Proveedor? proveedor;

  const ProveedorFormPanel({
    super.key,
    required this.onClose,
    required this.onProveedorCreated,
    this.proveedor,
  });

  @override
  State<ProveedorFormPanel> createState() => _ProveedorFormPanelState();
}

class _ProveedorFormPanelState extends State<ProveedorFormPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _horaAperturaController = TextEditingController(text: '09:00');
  final _horaCierreController = TextEditingController(text: '18:00');

  List<CategoriaProveedor> _categorias = [];
  int? _categoriaSeleccionada;
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

    // Inicializar controladores con datos del proveedor si existe
    if (widget.proveedor != null) {
      _nombreController.text = widget.proveedor!.nombre;
      _direccionController.text = widget.proveedor!.direccion;
      _telefonoController.text = widget.proveedor!.telefono.toString();
      _emailController.text = widget.proveedor!.email ?? '';
      _categoriaSeleccionada = widget.proveedor!.idCategoriaP;
      _horaAperturaController.text = widget.proveedor!.horaApertura;
      _horaCierreController.text = widget.proveedor!.horaCierre;
    }
    _cargarDatos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _horaAperturaController.dispose();
    _horaCierreController.dispose();
    super.dispose();
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
      final response = await CategoriaProveedorService.obtenerTodas();
      if (response['success']) {
        setState(() {
          _categorias = List<CategoriaProveedor>.from(response['data']);
        });
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      print('💥 Error en _cargarDatos: $e');
      _mostrarSnackBar('Error al cargar los datos', true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _validarNombreProveedor(String nombre) async {
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
      // Aquí debería ir la verificación del nombre en el servicio
      // Por ahora simplemente simulamos la validación
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _nombreExiste = false; // Reemplazar con la lógica real
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

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final proveedor = Proveedor(
        id: widget.proveedor?.id,
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: int.parse(
          _telefonoController.text.replaceAll(RegExp(r'\D'), ''),
        ),
        idCategoriaP: _categoriaSeleccionada!,
        email:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
        horaApertura: _horaAperturaController.text,
        horaCierre: _horaCierreController.text,
      );

      Map<String, dynamic> result;
      
      if (widget.proveedor != null) {
        // Actualizar proveedor existente
        result = await ProveedorService.actualizar(proveedor);
      } else {
        // Crear nuevo proveedor
        result = await ProveedorService.crear(proveedor);
      }

      if (result['success']) {
        _mostrarSnackBar(
          result['message'] ?? 'Proveedor ${widget.proveedor != null ? 'actualizado' : 'creado'} exitosamente',
          false,
        );
        widget.onProveedorCreated(true);
      } else {
        _mostrarSnackBar(
          result['message'] ?? 'Error al ${widget.proveedor != null ? 'actualizar' : 'crear'} el proveedor',
          true,
        );
      }
    } catch (e) {
      print('Error al guardar: $e');
      _mostrarSnackBar(
        'Error inesperado al ${widget.proveedor != null ? 'actualizar' : 'guardar'} el proveedor: ${e.toString()}',
        true,
      );
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 600;
    final panelWidth = isDesktop ? 500.0 : size.width * 0.92;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Fondo semitransparente con blur
            GestureDetector(
              onTap: _cerrarPanel,
              child: Container(
                color: Colors.black.withOpacity(0.3 * _animation.value),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 2 * _animation.value,
                    sigmaY: 2 * _animation.value,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Panel deslizante
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: panelWidth,
              child: Transform.translate(
                offset: Offset((1 - _animation.value) * panelWidth, 0),
                child: Material(
                  elevation: 8,
                  color: Colors.grey[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppBar(
                        title: Text(
                          widget.proveedor != null
                              ? 'Editar Proveedor'
                              : 'Nuevo Proveedor',
                        ),
                        backgroundColor: const Color(0xFFC2185B),
                        foregroundColor: Colors.white,
                        leading: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _cerrarPanel,
                        ),
                        elevation: 0,
                      ),
                      Expanded(
                        child:
                            _isLoadingData
                                ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFC2185B),
                                  ),
                                )
                                : Form(
                                  key: _formKey,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Encabezado
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFC2185B,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.business,
                                                color: Color(0xFFC2185B),
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Nuevo Proveedor',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFFC2185B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Ingresa los datos del proveedor',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 32),

                                        // Información básica
                                        Card(
                                          elevation: 0,
                                          color: Colors.grey[50],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey[200]!,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  'Ingresa los datos del proveedor',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),

                                                // Nombre
                                                TextFormField(
                                                  controller: _nombreController,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        'Nombre del proveedor *',
                                                    prefixIcon: const Icon(
                                                      Icons.business,
                                                    ),
                                                    border:
                                                        const OutlineInputBorder(),
                                                    helperText:
                                                        'Nombre comercial o razón social',
                                                    suffixIcon:
                                                        _validandoNombre
                                                            ? const SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      8.0,
                                                                    ),
                                                                child:
                                                                    CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                    ),
                                                              ),
                                                            )
                                                            : _nombreExiste
                                                            ? const Icon(
                                                              Icons.error,
                                                              color: Colors.red,
                                                            )
                                                            : _nombreController
                                                                .text
                                                                .isNotEmpty
                                                            ? const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                            )
                                                            : null,
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return 'El nombre es obligatorio';
                                                    }
                                                    if (value.trim().length <
                                                        2) {
                                                      return 'El nombre debe tener al menos 2 caracteres';
                                                    }
                                                    if (_nombreExiste) {
                                                      return 'Ya existe un proveedor con este nombre';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (value) {
                                                    if (value.trim().length >=
                                                        2) {
                                                      _validarNombreProveedor(
                                                        value.trim(),
                                                      );
                                                    }
                                                  },
                                                ),
                                                const SizedBox(height: 16),

                                                // Dirección
                                                TextFormField(
                                                  controller:
                                                      _direccionController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Dirección *',
                                                        prefixIcon: Icon(
                                                          Icons.location_on,
                                                        ),
                                                        border:
                                                            OutlineInputBorder(),
                                                        helperText:
                                                            'Dirección completa',
                                                      ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return 'La dirección es obligatoria';
                                                    }
                                                    if (value.trim().length <
                                                        5) {
                                                      return 'La dirección debe ser más detallada';
                                                    }
                                                    return null;
                                                  },
                                                ),

                                                const SizedBox(height: 16),

                                                // Email
                                                TextFormField(
                                                  controller: _emailController,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Email',
                                                    prefixIcon: Icon(
                                                      Icons.email,
                                                    ),
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Correo electrónico (opcional)',
                                                  ),
                                                  keyboardType:
                                                      TextInputType
                                                          .emailAddress,
                                                  validator: (value) {
                                                    if (value != null &&
                                                        value
                                                            .trim()
                                                            .isNotEmpty) {
                                                      // Validación simple de email
                                                      final emailRegex = RegExp(
                                                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                                      );
                                                      if (!emailRegex.hasMatch(
                                                        value.trim(),
                                                      )) {
                                                        return 'Ingresa un email válido';
                                                      }
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Contacto y Categoría
                                        Card(
                                          elevation: 0,
                                          color: Colors.grey[50],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey[200]!,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.phone,
                                                      color: Color(0xFFC2185B),
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Contacto y Categorización',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),

                                                // Teléfono
                                                TextFormField(
                                                  controller:
                                                      _telefonoController,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Teléfono *',
                                                    prefixIcon: Icon(
                                                      Icons.phone,
                                                    ),
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Número de teléfono principal',
                                                  ),
                                                  keyboardType:
                                                      TextInputType.phone,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return 'El teléfono es obligatorio';
                                                    }
                                                    if (value.trim().length <
                                                        7) {
                                                      return 'Ingresa un número de teléfono válido';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 16),

                                                // Categoría
                                                DropdownButtonFormField<int>(
                                                  value: _categoriaSeleccionada,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Categoría *',
                                                    prefixIcon: Icon(
                                                      Icons.category,
                                                    ),
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Tipo de productos que ofrece',
                                                  ),
                                                  items:
                                                      _categorias
                                                          .where(
                                                            (categoria) =>
                                                                categoria.id !=
                                                                null,
                                                          )
                                                          .map((categoria) {
                                                            return DropdownMenuItem<
                                                              int
                                                            >(
                                                              value:
                                                                  categoria.id!,
                                                              child: Text(
                                                                categoria
                                                                    .nombre,
                                                              ),
                                                            );
                                                          })
                                                          .toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _categoriaSeleccionada =
                                                          value;
                                                    });
                                                  },
                                                  validator: (value) {
                                                    if (value == null) {
                                                      return 'Selecciona una categoría';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Horarios de Atención
                                        Card(
                                          elevation: 0,
                                          color: Colors.grey[50],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey[200]!,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.schedule,
                                                      color: Color(0xFFC2185B),
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Horario de Atención',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),

                                                // Hora de apertura
                                                TextFormField(
                                                  controller:
                                                      _horaAperturaController,
                                                  decoration: const InputDecoration(
                                                    labelText:
                                                        'Hora de apertura *',
                                                    prefixIcon: Icon(
                                                      Icons.access_time,
                                                    ),
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        'Formato 24h (HH:mm)',
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return 'La hora de apertura es obligatoria';
                                                    }
                                                    final regex = RegExp(
                                                      r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$',
                                                    );
                                                    if (!regex.hasMatch(
                                                      value,
                                                    )) {
                                                      return 'Formato inválido. Use HH:mm (24h)';
                                                    }
                                                    return null;
                                                  },
                                                  onTap: () async {
                                                    final TimeOfDay?
                                                    picked = await showTimePicker(
                                                      context: context,
                                                      initialTime: TimeOfDay(
                                                        hour: int.parse(
                                                          _horaAperturaController
                                                              .text
                                                              .split(':')[0],
                                                        ),
                                                        minute: int.parse(
                                                          _horaAperturaController
                                                              .text
                                                              .split(':')[1],
                                                        ),
                                                      ),
                                                    );
                                                    if (picked != null) {
                                                      setState(() {
                                                        _horaAperturaController
                                                                .text =
                                                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                                      });
                                                    }
                                                  },
                                                  readOnly: true,
                                                ),
                                                const SizedBox(height: 16),

                                                // Hora de cierre
                                                TextFormField(
                                                  controller:
                                                      _horaCierreController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Hora de cierre *',
                                                        prefixIcon: Icon(
                                                          Icons.access_time,
                                                        ),
                                                        border:
                                                            OutlineInputBorder(),
                                                        helperText:
                                                            'Formato 24h (HH:mm)',
                                                      ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return 'La hora de cierre es obligatoria';
                                                    }
                                                    final regex = RegExp(
                                                      r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$',
                                                    );
                                                    if (!regex.hasMatch(
                                                      value,
                                                    )) {
                                                      return 'Formato inválido. Use HH:mm (24h)';
                                                    }
                                                    return null;
                                                  },
                                                  onTap: () async {
                                                    final TimeOfDay?
                                                    picked = await showTimePicker(
                                                      context: context,
                                                      initialTime: TimeOfDay(
                                                        hour: int.parse(
                                                          _horaCierreController
                                                              .text
                                                              .split(':')[0],
                                                        ),
                                                        minute: int.parse(
                                                          _horaCierreController
                                                              .text
                                                              .split(':')[1],
                                                        ),
                                                      ),
                                                    );
                                                    if (picked != null) {
                                                      setState(() {
                                                        _horaCierreController
                                                                .text =
                                                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                                      });
                                                    }
                                                  },
                                                  readOnly: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ),
                      ),
                      // Botones de acción
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _cerrarPanel,
                              icon: const Icon(Icons.close),
                              label: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 16),
                            FilledButton.icon(
                              onPressed: _isLoading ? null : _guardarProveedor,
                              icon:
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
                                      : const Icon(Icons.save),
                              label: const Text('Guardar Proveedor'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFC2185B),
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
          ],
        );
      },
    );
  }
}
