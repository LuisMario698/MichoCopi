import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../models/receta.dart';
import '../models/categoria_producto.dart';
import '../models/materia_prima.dart';
import '../services/producto_service.dart';
import '../services/receta_service.dart';
import '../services/proveedor_service.dart';
import '../services/materia_prima_service.dart';
import 'categoria_form_panel.dart';
import '../models/proveedor.dart';

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
  final _searchController = TextEditingController();
  List<CategoriaProducto> _categorias = [];
  List<Proveedor> _proveedores = [];
  List<MateriaPrima> _materiasPrimas = [];
  List<MateriaPrima> _selectedMateriasPrimas = [];
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _nombreExiste = false;
  bool _validandoNombre = false;
  bool _isRecipe = false;
  String _searchQuery = '';
  int? _categoriaSeleccionada;
  int? _proveedorSeleccionado;

  List<MateriaPrima> get _filteredMateriasPrimas => _materiasPrimas
      .where((material) =>
          material.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

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
    _nombreController.dispose();
    _precioController.dispose();
    _searchController.dispose();
    _animationController.dispose();
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
      if (categoriasResult['success'] == true) {        setState(() {
          _categorias = List<CategoriaProducto>.from(categoriasResult['data']);
        });
      }      // Obtener proveedores
      final proveedoresResult = await ProveedorService.obtenerTodos();
      if (proveedoresResult['success'] == true) {
        setState(() {
          _proveedores = List<Proveedor>.from(proveedoresResult['data']);
        });
      }      // Obtener materias primas
      try {
        final materiaPrimaService = MateriaPrimaService();
        final materiasPrimas = await materiaPrimaService.obtenerTodas();
        setState(() {
          _materiasPrimas = materiasPrimas;
        });
      } catch (e) {
        print('💥 Error al cargar materias primas: $e');
      }

      // Agregar materias primas de prueba si no hay datos
      if (_materiasPrimas.isEmpty) {
        setState(() {
          _materiasPrimas = [
            MateriaPrima(
              id: 1,
              nombre: 'Harina',
              stock: 100,
              idCategoriaMp: 1,
              fechaCreacion: DateTime.now(),
            ),
            MateriaPrima(
              id: 2,
              nombre: 'Azúcar',
              stock: 50,
              idCategoriaMp: 1,
              fechaCreacion: DateTime.now(),
            ),
            MateriaPrima(
              id: 3,
              nombre: 'Levadura',
              stock: 25,
              idCategoriaMp: 1,
              fechaCreacion: DateTime.now(),
            ),
          ];
        });
      }      // Agregar datos de prueba si no hay datos
      if (_categorias.isEmpty) {
        setState(() {
          _categorias = [
            CategoriaProducto(id: 1, nombre: 'Electrónicos', conCaducidad: false),
            CategoriaProducto(id: 2, nombre: 'Alimentos', conCaducidad: true),
            CategoriaProducto(id: 3, nombre: 'Medicamentos', conCaducidad: true),
            CategoriaProducto(id: 4, nombre: 'Ropa', conCaducidad: false),
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
  // La función _seleccionarFecha ha sido eliminada
  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que haya materias primas seleccionadas si es una receta
    if (_isRecipe && _selectedMateriasPrimas.isEmpty) {
      _mostrarSnackBar(
        'Debes seleccionar al menos una materia prima para la receta',
        true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create recipe first if necessary
      int? idReceta;
        if (_isRecipe && _selectedMateriasPrimas.isNotEmpty) {
        final recetaService = RecetaService();
        final List<int> materiaPrimaIds = _selectedMateriasPrimas.map((m) => m.id!).toList();        try {
          // Ya no necesitamos las cantidades porque no se guardan en la base de datos
          final receta = Receta(
            idsMps: materiaPrimaIds,
            // Las cantidades se generarán automáticamente con valor 1
          );
          
          final recetaCreada = await recetaService.crear(receta);
          idReceta = recetaCreada.id;
          print('✅ Receta creada exitosamente con ID: ${recetaCreada.id}');
        } catch (e) {
          print('❌ Error al crear la receta: $e');
          _mostrarSnackBar('Error al crear la receta: $e', true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }      // Create product with recipe if one was created
      final producto = Producto(
        nombre: _nombreController.text.trim(),
        precio: double.parse(_precioController.text),
        idCategoriaProducto: _categoriaSeleccionada!,
        idReceta: idReceta,
      );

      final result = await ProductoService.crearProducto(producto);

      if (result['success']) {
        print('✅ Producto creado exitosamente con receta: ${result['data'].id}');
        _mostrarSnackBar('Producto agregado exitosamente', false);
        widget.onProductoCreated(true);
      } else {
        _mostrarSnackBar(
          'Error al crear el producto: ${result['message']}',
          true,
        );
      }
    } catch (e) {
      print('❌ Error inesperado: $e');
      _mostrarSnackBar('Error inesperado: $e', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    setState(() {
      _categoriaSeleccionada = null;
      _proveedorSeleccionado = null;
      _nombreExiste = false;
      _validandoNombre = false;
      _isRecipe = false;
      _selectedMateriasPrimas.clear();
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
                                                                ),                                                // Se ha eliminado la visualización del icono de caducidad
                                                              ],
                                                            ),
                                                          );
                                                        })
                                                        .toList(),                                                onChanged: (value) {
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

                                // Sección de precio
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
                                              Icons.attach_money,
                                              color: Color(0xFFC2185B),
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Precio',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildPriceField(),
                                      ],
                                    ),
                                  ),
                                ),                                const SizedBox(height: 16),
                                
                                // La sección de caducidad ha sido eliminada

                                

                                // Modo receta y selección de materias primas
                                Card(
                                  elevation: 0,
                                  color: Colors.grey[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Encabezado de Receta
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.receipt_long,
                                              color: Color(0xFFC2185B),
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Receta',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        
                                        // Switch para activar modo receta
                                        SwitchListTile(
                                          title: Text(
                                            'Este producto requiere una receta',
                                            style: TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: Text(
                                            'Activa esta opción si el producto se elabora usando materias primas',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          value: _isRecipe,
                                          onChanged: (value) {
                                            setState(() {
                                              _isRecipe = value;
                                              if (!value) {
                                                _selectedMateriasPrimas.clear();
                                              }
                                            });
                                          },
                                          secondary: Icon(
                                            Icons.kitchen,
                                            color: Color(0xFFC2185B),
                                          ),
                                        ),

                                        if (_isRecipe) ...[
                                          SizedBox(height: 16),

                                          // Buscador de materias primas
                                          TextField(
                                            decoration: InputDecoration(
                                              labelText: 'Buscar materia prima',
                                              hintText: 'Escribe para buscar...',
                                              prefixIcon: Icon(
                                                Icons.search,
                                                color: Color(0xFFC2185B),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Color(0xFFC2185B),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                _searchQuery = value;
                                              });
                                            },
                                          ),
                                          SizedBox(height: 16),

                                          // Lista de materias primas disponibles
                                          Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ListView.builder(
                                              itemCount: _filteredMateriasPrimas.length,
                                              itemBuilder: (context, index) {
                                                final material = _filteredMateriasPrimas[index];
                                                final yaSeleccionado = _selectedMateriasPrimas.contains(material);
                                                return ListTile(
                                                  title: Text(
                                                    material.nombre,
                                                    style: TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                  subtitle: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.inventory_2_outlined,
                                                        size: 14,
                                                        color: material.stock > 10 ? Colors.green : Colors.orange,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Stock: ${material.stock}',
                                                        style: TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                  trailing: yaSeleccionado
                                                    ? IconButton(
                                                        icon: Icon(Icons.check_circle, color: Color(0xFFC2185B)),
                                                        onPressed: () {
                                                          setState(() {
                                                            _selectedMateriasPrimas.remove(material);
                                                          });
                                                        },
                                                      )
                                                    : OutlinedButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            _selectedMateriasPrimas.add(material);
                                                          });
                                                        },
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: Color(0xFFC2185B),
                                                          side: BorderSide(color: Color(0xFFC2185B)),
                                                        ),
                                                        child: Text('Agregar'),
                                                      ),
                                                );
                                              },
                                            ),
                                          ),

                                          if (_selectedMateriasPrimas.isNotEmpty) ...[
                                            SizedBox(height: 24),
                                            Text(
                                              'Materias Primas de la Receta',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey[300]!),
                                              ),
                                              child: Column(
                                                children: _selectedMateriasPrimas.map((material) {
                                                  return ListTile(
                                                    leading: Icon(Icons.check, color: Color(0xFFC2185B)),
                                                    title: Text(material.nombre),
                                                    trailing: IconButton(
                                                      icon: Icon(Icons.remove_circle_outline, color: Colors.red[300]),
                                                      onPressed: () {
                                                        setState(() {
                                                          _selectedMateriasPrimas.remove(material);
                                                        });
                                                      },
                                                      tooltip: 'Remover de la receta',
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ],
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
