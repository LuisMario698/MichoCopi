import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/categoria_mp.dart';
import '../services/categoria_mp_service.dart';

class CategoriaMpFormPanel extends StatefulWidget {
  final CategoriaMp? categoria;
  final VoidCallback onClose;
  final Function(bool) onCategoriaCreated;

  const CategoriaMpFormPanel({
    super.key,
    this.categoria,
    required this.onClose,
    required this.onCategoriaCreated,
  });

  @override
  State<CategoriaMpFormPanel> createState() => _CategoriaMpFormPanelState();
}

class _CategoriaMpFormPanelState extends State<CategoriaMpFormPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _unidadController = TextEditingController();
  final _fcController = TextEditingController();

  bool _isLoading = false;
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
    _inicializarFormulario();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    _unidadController.dispose();
    _fcController.dispose();
    super.dispose();
  }

  void _inicializarFormulario() {
    if (widget.categoria != null) {
      _nombreController.text = widget.categoria!.nombre;
    }
  }

  Future<void> _cerrarPanel() async {
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _validarNombreCategoria(String nombre) async {
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

  Future<void> _guardarCategoria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final categoria = CategoriaMp(
        id: widget.categoria?.id,
        nombre: _nombreController.text.trim(),
      );

      if (widget.categoria == null) {
        await CategoriaMpService().crear(categoria);
        _mostrarSnackBar('Categoría agregada exitosamente', false);
      } else {
        await CategoriaMpService().actualizar(categoria);
        _mostrarSnackBar('Categoría actualizada exitosamente', false);
      }

      widget.onCategoriaCreated(true);
      await _cerrarPanel();
    } catch (e) {
      print('Error al guardar: $e');
      _mostrarSnackBar('Error al guardar la categoría', true);
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
    _unidadController.clear();
    _fcController.clear();
    setState(() {
      _nombreExiste = false;
      _validandoNombre = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 600;
    final panelWidth = isDesktop ? 500.0 : size.width * 0.92;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
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
                  // Header
                  AppBar(
                    title: Text(
                      widget.categoria == null
                          ? 'Nueva Categoría MP'
                          : 'Editar Categoría MP',
                    ),
                    backgroundColor: const Color(0xFFC2185B),
                    foregroundColor: Colors.white,
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _cerrarPanel,
                    ),
                    elevation: 0,
                  ),
                  // Content
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.category,
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
                                      Text(
                                        widget.categoria == null
                                            ? 'Nueva Categoría'
                                            : 'Editar Categoría',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFC2185B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Categoría de materia prima',
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
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
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
                                        labelText: 'Nombre de la categoría *',
                                        prefixIcon: const Icon(
                                          Icons.category,
                                          color: Color(0xFFC2185B),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        helperText:
                                            'Ejemplo: Carnes, Lácteos, Cereales',
                                        suffixIcon:
                                            _validandoNombre
                                                ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      8.0,
                                                    ),
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
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
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                )
                                                : null,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'El nombre es obligatorio';
                                        }
                                        if (value.trim().length < 2) {
                                          return 'El nombre debe tener al menos 2 caracteres';
                                        }
                                        if (_nombreExiste) {
                                          return 'Ya existe una categoría con este nombre';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        if (value.trim().length >= 2) {
                                          _validarNombreCategoria(value.trim());
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _unidadController,
                                      decoration: InputDecoration(
                                        labelText: 'Unidad de medida *',
                                        prefixIcon: const Icon(
                                          Icons.straighten,
                                          color: Color(0xFFC2185B),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        helperText:
                                            'Ejemplo: kg, litros, unidades, gramos',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'La unidad de medida es obligatoria';
                                        }
                                        if (value.trim().length < 1) {
                                          return 'La unidad debe tener al menos 1 caracter';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Factor de conversión
                            Card(
                              elevation: 0,
                              color: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.calculate,
                                          color: Color(0xFFC2185B),
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Factor de Conversión',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'El factor de conversión se usa para convertir unidades. Por ejemplo, si la unidad es "kg" y quieres mostrar en gramos, el factor sería 1000.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _fcController,
                                      decoration: InputDecoration(
                                        labelText: 'Factor de conversión *',
                                        prefixIcon: const Icon(
                                          Icons.calculate,
                                          color: Color(0xFFC2185B),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        helperText:
                                            'Número entero para conversión de unidades',
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El factor de conversión es requerido';
                                        }
                                        final fc = int.tryParse(value);
                                        if (fc == null || fc <= 0) {
                                          return 'El factor debe ser un número entero mayor a 0';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Ejemplos de factor de conversión
                            Card(
                              elevation: 0,
                              color: Colors.blue[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.blue[200]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Ejemplos de Factores de Conversión',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '• Kilogramos → Gramos: 1000\n'
                                      '• Litros → Mililitros: 1000\n'
                                      '• Metros → Centímetros: 100\n'
                                      '• Unidades → Unidades: 1',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
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
                          onPressed: _isLoading ? null : _guardarCategoria,
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: Text(
                            widget.categoria == null
                                ? 'Crear Categoría'
                                : 'Actualizar Categoría',
                          ),
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
        );
      },
    );
  }
}
