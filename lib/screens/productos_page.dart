import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/producto_form_panel.dart';
import '../services/producto_service.dart';
import '../models/producto.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  bool _mostrarFormulario = false;
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

  void _toggleFormulario() {
    setState(() {
      _mostrarFormulario = !_mostrarFormulario;
    });
  }

  void _onProductoCreated(bool success) {
    if (success) {
      _toggleFormulario();
      _cargarDatos(); // Recargar lista de productos
    }
  }

  List<dynamic> get _productosFiltrados {
    return _productos.where((producto) {
      final matchesCategoria = _categoriaSeleccionada == 'Todas las categorías' ||
          producto.categoria == _categorias
              .firstWhere((cat) => cat.nombre == _categoriaSeleccionada)
              .id;
      final matchesSearch = _searchQuery.isEmpty ||
          producto.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategoria && matchesSearch;
    }).toList();
  }

  // Formatear fecha en formato dd/MM/yyyy
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  // Calcular color basado en la proximidad de la fecha de caducidad
  Color _calcularColorCaducidad(DateTime fecha) {
    final now = DateTime.now();
    final diferencia = fecha.difference(now).inDays;

    if (diferencia < 0) {
      return Colors.red[700]!; // Producto caducado
    } else if (diferencia <= 7) {
      return Colors.orange[700]!; // Próximo a caducar (7 días o menos)
    } else if (diferencia <= 30) {
      return Colors.orange[400]!; // Advertencia (30 días o menos)
    } else {
      return Colors.green[700]!; // Fecha lejana
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Página principal
        PageWrapper(
          title: 'Productos',
          actions: [
            ElevatedButton.icon(
              onPressed: _toggleFormulario,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Producto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2185B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
          child: Column(
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
                      DropdownButton<String>(
                        value: _categoriaSeleccionada,
                        items: [
                          'Todas las categorías',
                          ..._categorias.map((cat) => cat.nombre).toList(),
                        ]
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
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
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Grid de productos
              Expanded(
                child: _isLoading
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
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  MediaQuery.of(context).size.width > 1200
                                      ? 4
                                      : MediaQuery.of(context).size.width > 800
                                          ? 3
                                          : 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _productosFiltrados.length,
                            itemBuilder: (context, index) {
                              final producto = _productosFiltrados[index];
                              final categoria = _categorias.firstWhere(
                                (cat) => cat.id == producto.categoria,
                                orElse: () => Categoria(
                                  nombre: 'Sin categoría',
                                  conCaducidad: false,
                                ),
                              );

                              return Card(
                                elevation: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Imagen del producto
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.icecream,
                                              size: 64,
                                              color: Color(0xFFC2185B),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFC2185B).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                categoria.nombre,
                                                style: const TextStyle(
                                                  color: Color(0xFFC2185B),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Información del producto
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Nombre del producto
                                            Text(
                                              producto.nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Spacer(),
                                            // Precio y stock en la misma fila
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                // Precio
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFC2185B).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '\$${producto.precio.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFC2185B),
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                // Fecha de caducidad si aplica
                                                if (categoria.conCaducidad && producto.caducidad != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _calcularColorCaducidad(producto.caducidad!).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      _formatearFecha(producto.caducidad!),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _calcularColorCaducidad(producto.caducidad!),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),

        // Panel deslizante y overlay semitransparente
        if (_mostrarFormulario) ...[
          // Overlay semitransparente con efecto de blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: GestureDetector(
                onTap: _toggleFormulario,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
          // Panel del formulario
          ProductoFormPanel(
            onClose: _toggleFormulario,
            onProductoCreated: _onProductoCreated,
          ),
        ],
      ],
    );
  }
}
