import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../models/categoria_producto.dart';
import '../models/proveedor.dart';
import '../services/producto_service.dart';
import '../services/proveedor_service.dart';
import 'categoria_form_panel.dart';

class ProductoFormPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Function(bool) onProductoCreated;

  const ProductoFormPanel({
    super.key,
    required this.onClose,
    required this.onProductoCreated,
  });

  @override
  State<ProductoFormPanel> createState() => _ProductoFormPanelState();
}

class _ProductoFormPanelState extends State<ProductoFormPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();

  List<Categoria> _categorias = [];
  List<Proveedor> _proveedores = [];

  int? _categoriaSeleccionada;
  int? _proveedorSeleccionado;
  DateTime? _fechaCaducidad;

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _nombreExiste = false;
  bool _validandoNombre = false;

  // Función para verificar si la categoría seleccionada permite caducidad
  bool get _categoriaPermiteCaducidad {
    if (_categoriaSeleccionada == null) return false;

    try {
      final categoriaSeleccionada = _categorias.firstWhere(
        (categoria) => categoria.id == _categoriaSeleccionada,
      );
      return categoriaSeleccionada.conCaducidad;
    } catch (e) {
      print('⚠️ Error al buscar categoría con ID $_categoriaSeleccionada: $e');
      return false;
    }
  }

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
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
      print('🔄 Iniciando carga de datos...');

      // Obtener categorías
      final categoriasResult = await ProductoService.obtenerCategorias();
      if (categoriasResult['success'] == true) {
        setState(() {
          _categorias = List<Categoria>.from(categoriasResult['data']);
        });
      }

      // Obtener proveedores
      final proveedoresResult = await ProveedorService.obtenerTodos();
      if (proveedoresResult['success'] == true) {
        setState(() {
          _proveedores = List<Proveedor>.from(proveedoresResult['data']);
        });
      }

      // Agregar datos de prueba si no hay datos
      if (_categorias.isEmpty) {
        setState(() {
          _categorias = [
            Categoria(id: 1, nombre: 'Electrónicos', conCaducidad: false),
            Categoria(id: 2, nombre: 'Alimentos', conCaducidad: true),
            Categoria(id: 3, nombre: 'Medicamentos', conCaducidad: true),
            Categoria(id: 4, nombre: 'Ropa', conCaducidad: false),
          ];
        });
      }

      if (_proveedores.isEmpty) {
        setState(() {
          _proveedores = [
            Proveedor(
              id: 1,
              nombre: 'Proveedor A',
              direccion: 'Calle 123',
              telefono: 123456789,
              idCategoriaP: 1,
              email: 'proveedora@ejemplo.com',
              horaApertura: '09:00',
              horaCierre: '18:00',
            ),
            Proveedor(
              id: 2,
              nombre: 'Proveedor B',
              direccion: 'Avenida 456',
              telefono: 987654321,
              idCategoriaP: 1,
              email: 'proveedorb@ejemplo.com',
              horaApertura: '08:00',
              horaCierre: '17:00',
            ),
            Proveedor(
              id: 3,
              nombre: 'Proveedor C',
              direccion: 'Plaza 789',
              telefono: 555444333,
              idCategoriaP: 1,
              email: 'proveedorc@ejemplo.com',
              horaApertura: '10:00',
              horaCierre: '19:00',
            ),
          ];
        });
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

  Future<void> _seleccionarFecha() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Seleccionar fecha de caducidad',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaCaducidad = fechaSeleccionada;
      });
    }
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final producto = Producto(
        nombre: _nombreController.text.trim(),
        precio: double.parse(_precioController.text),
        stock: int.parse(_stockController.text),
        idCategoriaProducto: _categoriaSeleccionada!,
        caducidad: _fechaCaducidad,
      );

      final result = await ProductoService.crearProducto(producto);

      if (result['success']) {
        _mostrarSnackBar('Producto agregado exitosamente', false);
        widget.onProductoCreated(true);
      } else {
        _mostrarSnackBar(
          result['message'] ?? 'Error al guardar el producto',
          true,
        );
      }
    } catch (e) {
      print('💥 Error al guardar: $e');
      _mostrarSnackBar('Error al guardar el producto', true);
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
    _precioController.clear();
    _stockController.clear();
    setState(() {
      _categoriaSeleccionada = null;
      _proveedorSeleccionado = null;
      _fechaCaducidad = null;
      _nombreExiste = false;
      _validandoNombre = false;
    });
  }

  Future<void> _validarNombreProducto(String nombre) async {
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
      final result = await ProductoService.verificarNombreProducto(
        nombre.trim(),
      );

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

  Future<void> _agregarNuevaCategoria() async {
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (BuildContext context) => CategoriaFormPanel(
            onClose: () => Navigator.of(context).pop(),
            onCategoriaCreated: (success) {
              Navigator.of(context).pop();
              if (success) {
                _mostrarSnackBar('Categoría creada exitosamente', false);
                _cargarDatos(); // Recargar categorías
              }
            },
          ),
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _precioController,
      decoration: const InputDecoration(
        labelText: 'Precio *',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
        helperText: 'Ingrese el precio sin el signo \$',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El precio es obligatorio';
        }
        final precio = double.tryParse(value);
        if (precio == null || precio <= 0) {
          return 'Ingresa un precio válido mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      decoration: const InputDecoration(
        labelText: 'Stock inicial *',
        prefixIcon: Icon(Icons.inventory),
        border: OutlineInputBorder(),
        suffixText: 'unidades',
        helperText: 'Cantidad inicial disponible',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El stock es obligatorio';
        }
        final stock = int.tryParse(value);
        if (stock == null || stock < 0) {
          return 'Ingresa un stock válido (0 o mayor)';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final panelWidth =
        isDesktop ? 600.0 : MediaQuery.of(context).size.width * 0.92;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((1 - _animation.value) * panelWidth, 0),
          child: child,
        );
      },
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: panelWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: const Text('Nuevo Producto'),
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
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _nombreController,
                                          decoration: InputDecoration(
                                            labelText: 'Nombre del producto *',
                                            prefixIcon: const Icon(
                                              Icons.shopping_bag,
                                            ),
                                            border: const OutlineInputBorder(),
                                            helperText:
                                                'El nombre debe ser único',
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
                                              return 'Ya existe un producto con este nombre';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            if (value.trim().length >= 2) {
                                              _validarNombreProducto(
                                                value.trim(),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Categorización
                                Card(
                                  elevation: 0,
                                  color: Colors.grey[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.category_outlined,
                                              color: Color(0xFFC2185B),
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Categorización',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: DropdownButtonFormField<
                                                int
                                              >(
                                                value: _categoriaSeleccionada,
                                                decoration: InputDecoration(
                                                  labelText: 'Categoría *',
                                                  prefixIcon: const Icon(
                                                    Icons.category,
                                                    color: Color(0xFFC2185B),
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                8,
                                                              ),
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Color(
                                                            0xFFC2185B,
                                                          ),
                                                        ),
                                                      ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                ),
                                                icon: const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Color(0xFFC2185B),
                                                ),
                                                dropdownColor: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  categoria
                                                                      .nombre,
                                                                ),
                                                                if (categoria
                                                                    .conCaducidad) ...[
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  const Icon(
                                                                    Icons
                                                                        .schedule,
                                                                    size: 16,
                                                                    color:
                                                                        Colors
                                                                            .orange,
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          );
                                                       })
                                                        .toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _categoriaSeleccionada =
                                                        value;
                                                    if (!_categoriaPermiteCaducidad) {
                                                      _fechaCaducidad = null;
                                                    }
                                                  });
                                                },
                                                validator: (value) {
                                                  if (value == null) {
                                                    return 'Selecciona una categoría';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: _agregarNuevaCategoria,
                                              icon: const Icon(
                                                Icons.add_circle,
                                              ),
                                              tooltip:
                                                  'Agregar nueva categoría',
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFC2185B,
                                                ),
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<int>(
                                          value: _proveedorSeleccionado,
                                          decoration: InputDecoration(
                                            labelText: 'Proveedor *',
                                            prefixIcon: const Icon(
                                              Icons.business,
                                              color: Color(0xFFC2185B),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            focusedBorder:
                                                const OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                  borderSide: BorderSide(
                                                    color: Color(0xFFC2185B),
                                                  ),
                                                ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                            color: Color(0xFFC2185B),
                                          ),
                                          dropdownColor: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          items:
                                              _proveedores
                                                  .where(
                                                    (proveedor) =>
                                                        proveedor.id != null,
                                                  )
                                                  .map((proveedor) {
                                                    return DropdownMenuItem<
                                                      int
                                                    >(
                                                      value: proveedor.id!,
                                                      child: Text(
                                                        proveedor.nombre,
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _proveedorSeleccionado = value;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Selecciona un proveedor';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Inventario y Precio
                                Card(
                                  elevation: 0,
                                  color: Colors.grey[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              color: Color(0xFFC2185B),
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Inventario y Precio',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: _buildPriceField()),
                                            const SizedBox(width: 16),
                                            Expanded(child: _buildStockField()),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Caducidad (condicional)
                                if (_categoriaPermiteCaducidad)
                                  Card(
                                    elevation: 0,
                                    color: Colors.grey[50],
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_outlined,
                                                color: Colors.orange,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Fecha de Caducidad',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          InkWell(
                                            onTap: _seleccionarFecha,
                                            child: InputDecorator(
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Fecha de caducidad (opcional)',
                                                prefixIcon: Icon(
                                                  Icons.calendar_today,
                                                ),
                                                border: OutlineInputBorder(),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _fechaCaducidad != null
                                                        ? '${_fechaCaducidad!.day}/${_fechaCaducidad!.month}/${_fechaCaducidad!.year}'
                                                        : 'Seleccionar fecha',
                                                    style: TextStyle(
                                                      color:
                                                          _fechaCaducidad !=
                                                                  null
                                                              ? Colors.black87
                                                              : Colors
                                                                  .grey[600],
                                                    ),
                                                  ),
                                                  if (_fechaCaducidad != null)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.clear,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _fechaCaducidad =
                                                              null;
                                                        });
                                                      },
                                                      tooltip: 'Limpiar fecha',
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 32),

                                // Botones de acción
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        '* Campos obligatorios',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed:
                                                  _isLoading
                                                      ? null
                                                      : () {
                                                        _limpiarFormulario();
                                                        _cerrarPanel();
                                                      },
                                              icon: const Icon(Icons.close),
                                              label: const Text('Cancelar'),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 2,
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  _isLoading
                                                      ? null
                                                      : _guardarProducto,
                                              icon:
                                                  _isLoading
                                                      ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                      : const Icon(Icons.save),
                                              label: const Text(
                                                'Guardar Producto',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFC2185B,
                                                ),
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
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
          ),
        ),
      ),
    );
  }
}
