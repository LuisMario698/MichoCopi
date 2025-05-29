import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/categoria_producto.dart';
import '../services/producto_service.dart';

class CategoriaFormPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Function(bool) onCategoriaCreated;

  const CategoriaFormPanel({
    super.key,
    required this.onClose,
    required this.onCategoriaCreated,
  });

  @override
  State<CategoriaFormPanel> createState() => _CategoriaFormPanelState();
}

class _CategoriaFormPanelState extends State<CategoriaFormPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  bool _conCaducidad = false;
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    super.dispose();
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
      final result = await ProductoService.verificarNombreCategoria(nombre.trim());

      if (mounted) {
        setState(() {
          _nombreExiste = result['existe'] ?? false;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nombreValidation = await ProductoService.verificarNombreCategoria(
      _nombreController.text.trim(),
    );
    if (nombreValidation['success'] && nombreValidation['existe'] == true) {
      _mostrarSnackBar('Ya existe una categoría con este nombre', true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoria = Categoria(
        nombre: _nombreController.text.trim(),
        conCaducidad: _conCaducidad,
      );

      final result = await ProductoService.crearCategoria(categoria);

      if (result['success']) {
        _mostrarSnackBar('Categoría creada exitosamente', false);
        widget.onCategoriaCreated(true);
      } else {
        _mostrarSnackBar('Error al crear la categoría', true);
      }
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
                  child: Container(
                    color: Colors.transparent,
                  ),
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
                        title: const Text('Nueva Categoría'),
                        backgroundColor: const Color(0xFFC2185B),
                        foregroundColor: Colors.white,
                        leading: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _cerrarPanel,
                        ),
                        elevation: 0,
                      ),
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
                                        color: const Color(0xFFC2185B).withOpacity(0.1),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Nueva Categoría',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFC2185B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ingresa los datos de la categoría',
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
                                            prefixIcon: const Icon(Icons.category),
                                            border: const OutlineInputBorder(),
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
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Configuración de caducidad
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
                                              Icons.schedule,
                                              color: Color(0xFFC2185B),
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Configuración de Caducidad',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        SwitchListTile(
                                          value: _conCaducidad,
                                          onChanged: (value) {
                                            setState(() {
                                              _conCaducidad = value;
                                            });
                                          },
                                          title: const Text('Requiere fecha de caducidad'),
                                          subtitle: Text(
                                            _conCaducidad
                                                ? 'Los productos de esta categoría tendrán fecha de caducidad'
                                                : 'Los productos de esta categoría NO tendrán fecha de caducidad',
                                            style: TextStyle(
                                              color: _conCaducidad
                                                  ? Colors.orange[700]
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          activeColor: const Color(0xFFC2185B),
                                          secondary: Icon(
                                            _conCaducidad
                                                ? Icons.schedule
                                                : Icons.schedule_outlined,
                                            color: _conCaducidad
                                                ? Colors.orange
                                                : Colors.grey,
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
                              onPressed: _isLoading ? null : _guardarCategoria,
                              icon: _isLoading
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
                              label: const Text('Guardar Categoría'),
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
