import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/producto_form_panel.dart';
import '../widgets/producto_detail_panel.dart';
import '../services/producto_service.dart';
import '../models/producto.dart';
import '../models/categoria_producto.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  bool _mostrarFormulario = false;
  bool _mostrarDetalles = false;
  Producto? _productoSeleccionado;
  bool _isLoading = true;
  List<dynamic> _productos = [];
  List<Categoria> _categorias = [];
  String _categoriaSeleccionada = 'Todas las categorías';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        ProductoService.obtenerProductos(),
        ProductoService.obtenerCategorias(),
      ]);

      final productosResult = futures[0];
      final categoriasResult = futures[1];

      if (productosResult['success']) {
        setState(() {
          _productos = productosResult['data'];
        });
      }

      if (categoriasResult['success']) {
        setState(() {
          _categorias = categoriasResult['data'];
        });
      }
    } catch (e) {
      print('💥 Error cargando datos: $e');
      // Mostrar snackbar con error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cerrarTodosLosPaneles() {
    setState(() {
      _mostrarFormulario = false;
      _mostrarDetalles = false;
      _productoSeleccionado = null;
    });
  }

  void _toggleFormulario() {
    setState(() {
      if (_mostrarDetalles) {
        _mostrarDetalles = false;
        _productoSeleccionado = null;
      }
      _mostrarFormulario = !_mostrarFormulario;
    });
  }

  void _onProductoCreated(bool success) {
    if (success) {
      _cerrarTodosLosPaneles();
      Future.microtask(() => _cargarDatos());
    }
  }

  void _toggleDetalles(Producto? producto) {
    setState(() {
      if (_mostrarFormulario) {
        _mostrarFormulario = false;
      }
      _mostrarDetalles = !_mostrarDetalles;
      _productoSeleccionado = _mostrarDetalles ? producto : null;
    });
  }

  void _onProductoUpdated(bool success) {
    if (success) {
      // Solo recargamos los datos sin cerrar el panel
      _cargarDatos().then((_) {
        // Actualizamos el producto seleccionado con los nuevos datos
        if (_productoSeleccionado != null) {
          final productoActualizado = _productos.firstWhere(
            (p) => p.id == _productoSeleccionado!.id,
            orElse: () => _productoSeleccionado!,
          );
          setState(() {
            _productoSeleccionado = productoActualizado;
          });
        }
      });
    }
  }

  List<dynamic> get _productosFiltrados {
    return _productos.where((producto) {
      final matchesCategoria =
          _categoriaSeleccionada == 'Todas las categorías' ||
          producto.idCategoriaProducto ==
              _categorias
                  .firstWhere((cat) => cat.nombre == _categoriaSeleccionada)
                  .id;
      final matchesSearch =
          _searchQuery.isEmpty ||
          producto.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategoria && matchesSearch;
    }).toList();
  }

  // Formatear fecha en formato dd/MM/yyyy
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Map<String, dynamic> _calcularEstadoCaducidad(DateTime fecha) {
    // Crear fecha actual sin la hora para comparar solo las fechas
    final now = DateTime.now();
    final fechaActual = DateTime(now.year, now.month, now.day);
    final fechaVencimiento = DateTime(fecha.year, fecha.month, fecha.day);

    // Calcular diferencia en días
    final diferencia = fechaVencimiento.difference(fechaActual).inDays;

    if (diferencia < 0) {
      // Producto vencido
      return {
        'color': Colors.red[700]!,
        'backgroundColor': Colors.red[50]!,
        'icon': Icons.warning_rounded,
        'mensaje': 'Vencido (${-diferencia}d)',
      };
    } else if (diferencia <= 7) {
      // Próximo a vencer (7 días o menos)
      return {
        'color': Colors.orange[700]!,
        'backgroundColor': Colors.orange[50]!,
        'icon': Icons.access_time,
        'mensaje': diferencia == 0 ? 'Vence hoy' : '${diferencia}d restantes',
      };
    } else {
      // Vigente (más de 7 días)
      return {
        'color': Colors.green[700]!,
        'backgroundColor': Colors.green[50]!,
        'icon': Icons.check_circle_outline,
        'mensaje': 'Vigente ($diferencia días)',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Página principal
        Scaffold(
          appBar: AppBar(
            title: const Text('Productos'),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC2185B), Color(0xFFE91E63)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC2185B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleFormulario,
                        borderRadius: BorderRadius.circular(30),
                        splashColor: Colors.white.withOpacity(0.2),
                        highlightColor: Colors.white.withOpacity(0.1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                shaderCallback:
                                    (bounds) => const LinearGradient(
                                      colors: [Colors.white, Colors.white70],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                child: const Icon(
                                  Icons.add_circle,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Nuevo Producto',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 8,
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
                ),
              ),
            ],
            backgroundColor: const Color(0xFFC2185B),
            elevation: 2,
          ),
          body: Column(
            children: [
              // Filtros y búsqueda
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Buscar productos...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: DropdownButton<String>(
                          value: _categoriaSeleccionada,
                          items:
                              [
                                    'Todas las categorías',
                                    ..._categorias.map((cat) => cat.nombre),
                                  ]
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Row(
                                        children: [
                                          Icon(
                                            item == 'Todas las categorías'
                                                ? Icons.category_outlined
                                                : Icons.label_outlined,
                                            size: 20,
                                            color: const Color(0xFFC2185B),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _categoriaSeleccionada = value;
                              });
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFFC2185B),
                          ),
                          underline:
                              const SizedBox(), // Elimina la línea inferior
                          isExpanded: false,
                          borderRadius: BorderRadius.circular(8),
                          dropdownColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Grid de productos
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFC2185B),
                          ),
                        )
                        : _productosFiltrados.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay productos disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agrega tu primer producto con el botón "Nuevo Producto"',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width > 1200
                                        ? 4
                                        : MediaQuery.of(context).size.width >
                                            800
                                        ? 3
                                        : MediaQuery.of(context).size.width >
                                            600
                                        ? 2
                                        : 1,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: _productosFiltrados.length,
                          itemBuilder: (context, index) {
                            final producto = _productosFiltrados[index];
                            final categoria = _categorias.firstWhere(
                              (cat) => cat.id == producto.idCategoriaProducto,
                              orElse:
                                  () => Categoria(
                                    id: 0,
                                    nombre: 'Sin categoría',
                                    conCaducidad: false,
                                  ),
                            );
                            return InkWell(
                              onTap: () => _toggleDetalles(producto),
                              child: Card(
                                elevation: 3,
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Sección superior con gradiente e icono
                                    Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(
                                              0xFFC2185B,
                                            ).withOpacity(0.15),
                                            Colors.grey[50]!,
                                          ],
                                          stops: const [0.3, 1.0],
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.icecream_rounded,
                                          size: 120,
                                          color: const Color(
                                            0xFFC2185B,
                                          ).withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                    // Contenido del producto
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Nombre del producto (más grande)
                                            Text(
                                              producto.nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 30,
                                                height: 1.2,
                                                color: Color(0xFF1E1E1E),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            // Categoría justo debajo del nombre
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFC2185B,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.category_outlined,
                                                    size: 16,
                                                    color: const Color(
                                                      0xFFC2185B,
                                                    ).withOpacity(0.8),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    categoria.nombre,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: const Color(
                                                        0xFFC2185B,
                                                      ).withOpacity(0.8),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            // Precio abajo a la derecha
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFC2185B,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '\$${producto.precio.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontSize: 23,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ), // Overlay y efecto de blur
        if (_mostrarFormulario || _mostrarDetalles)
          Positioned.fill(
            child: Stack(
              children: [
                // Capa de fondo oscuro
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
                // Capa de blur
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Gesture detector para cerrar
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (_mostrarFormulario) {
                        _toggleFormulario();
                      } else {
                        _toggleDetalles(null);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        if (_mostrarFormulario)
          ProductoFormPanel(
            onClose: _toggleFormulario,
            onProductoCreated: _onProductoCreated,
          ),
        if (_mostrarDetalles && _productoSeleccionado != null)
          ProductoDetailPanel(
            producto: _productoSeleccionado!,
            categoria: _categorias.firstWhere(
              (cat) => cat.id == _productoSeleccionado!.idCategoriaProducto,
              orElse:
                  () => Categoria(
                    id: 0,
                    nombre: 'Sin categoría',
                    conCaducidad: false,
                  ),
            ),
            onClose: () => _toggleDetalles(null),
            onProductoUpdated: _onProductoUpdated,
          ),
      ],
    );
  }
}
