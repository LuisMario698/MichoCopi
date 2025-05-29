import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../models/carrito_item.dart';
import '../services/producto_service.dart';
import '../services/venta_service.dart';

class NuevaVentaModal extends StatefulWidget {
  const NuevaVentaModal({super.key});

  @override
  State<NuevaVentaModal> createState() => _NuevaVentaModalState();
}

class _NuevaVentaModalState extends State<NuevaVentaModal> {
  final TextEditingController _busquedaController = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();
  
  List<Producto> _productosDisponibles = [];
  List<Producto> _productosFiltrados = [];
  List<CarritoItem> _carrito = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _busquedaController.addListener(_filtrarProductos);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _clienteController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await ProductoService.obtenerProductos();
      if (resultado['success']) {
        setState(() {
          _productosDisponibles = resultado['data'] as List<Producto>;
          _productosFiltrados = _productosDisponibles;
        });
      } else {
        _mostrarError('Error al cargar productos: ${resultado['message']}');
      }
    } catch (e) {
      _mostrarError('Error al cargar productos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filtrarProductos() {
    final query = _busquedaController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;      _productosFiltrados = _productosDisponibles
          .where((producto) =>
              producto.nombre.toLowerCase().contains(query))
          .toList();
    });
  }

  void _agregarAlCarrito(Producto producto) {
    setState(() {
      final index = _carrito.indexWhere((item) => item.productoId == producto.id);
      
      if (index != -1) {
        // Si ya existe, aumentar cantidad
        final item = _carrito[index];
        _carrito[index] = item.copyWith(cantidad: item.cantidad + 1);
      } else {
        // Agregar nuevo item al carrito
        _carrito.add(CarritoItem(
          productoId: producto.id!,
          nombre: producto.nombre,
          precio: producto.precio,
          cantidad: 1,
          stock: null, // Stock is now null since we don't manage inventory
        ));
      }
    });

    // Limpiar búsqueda después de agregar
    _busquedaController.clear();
  }
  void _modificarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarDelCarrito(index);
    } else {
      setState(() {
        final item = _carrito[index];
        _carrito[index] = item.copyWith(cantidad: nuevaCantidad);
      });
    }
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
  }

  double get _total {
    return _carrito.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }
  Future<void> _procesarVenta() async {
    if (_carrito.isEmpty) {
      _mostrarError('El carrito está vacío');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await VentaService.procesarVenta(
        carrito: _carrito,
        cliente: _clienteController.text.trim().isEmpty 
            ? null 
            : _clienteController.text.trim(),
      );      if (resultado['success']) {
        final total = _total;
        final cliente = _clienteController.text.trim().isEmpty 
            ? 'Cliente Anónimo' 
            : _clienteController.text.trim();
        
        _mostrarExito(
          '¡Venta completada exitosamente!\n\n'
          'Cliente: $cliente\n'
          'Total: \$${total.toStringAsFixed(2)}\n'
          'ID de Venta: ${resultado['venta_id']}'
        );
        
        // Esperar un momento para que el usuario vea el mensaje
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true); // Retornar true para indicar éxito
        }
      } else {
        _mostrarError(resultado['message'] ?? 'Error al procesar la venta');
      }
    } catch (e) {
      _mostrarError('Error al procesar la venta: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header del modal
            _buildHeader(),
            
            // Contenido principal
            Expanded(
              child: Row(
                children: [
                  // Panel izquierdo - Búsqueda y productos
                  Expanded(
                    flex: 2,
                    child: _buildBusquedaPanel(),
                  ),
                  
                  // Divisor
                  Container(
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  
                  // Panel derecho - Carrito
                  Expanded(
                    flex: 2,
                    child: _buildCarritoPanel(),
                  ),
                ],
              ),
            ),
            
            // Footer con total y acciones
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC2185B),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.point_of_sale_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Nueva Venta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildBusquedaPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información del cliente
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _clienteController,
            decoration: InputDecoration(
              labelText: 'Cliente (opcional)',
              hintText: 'Nombre del cliente...',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC2185B), width: 2),
              ),
            ),
          ),
        ),
        
        // Barra de búsqueda de productos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _busquedaController,
            decoration: InputDecoration(
              labelText: 'Buscar producto',
              hintText: 'Escribe el nombre del producto...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busquedaController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _busquedaController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC2185B), width: 2),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Lista de productos
        Expanded(
          child: _buildListaProductos(),
        ),
      ],
    );
  }

  Widget _buildListaProductos() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC2185B)),
        ),
      );
    }

    if (_productosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching 
                  ? 'No se encontraron productos'
                  : 'No hay productos disponibles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _productosFiltrados.length,
      itemBuilder: (context, index) {
        final producto = _productosFiltrados[index];
        final enCarrito = _carrito.any((item) => item.productoId == producto.id);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFC2185B).withOpacity(0.1),
              child: Text(
                producto.nombre.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFC2185B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),            title: Text(
              producto.nombre,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('\$${producto.precio.toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (enCarrito)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'En carrito',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _agregarAlCarrito(producto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2185B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarritoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFFC2185B),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Carrito (${_carrito.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC2185B),
                ),
              ),
              const Spacer(),
              if (_carrito.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _carrito.clear();
                    });
                  },
                  child: const Text('Limpiar'),
                ),
            ],
          ),
        ),
        
        Expanded(
          child: _buildListaCarrito(),
        ),
      ],
    );
  }

  Widget _buildListaCarrito() {
    if (_carrito.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'El carrito está vacío',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Busca y agrega productos',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _carrito.length,
      itemBuilder: (context, index) {
        final item = _carrito[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.precio.toStringAsFixed(2)} c/u',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Controles de cantidad
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _modificarCantidad(index, item.cantidad - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 20,
                      color: Colors.red,
                    ),
                    
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.cantidad}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    
                    IconButton(
                      onPressed: item.puedeAumentar 
                          ? () => _modificarCantidad(index, item.cantidad + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 20,
                      color: item.puedeAumentar ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                // Subtotal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC2185B),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _eliminarDelCarrito(index),
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 18,
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total de la venta',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC2185B),
                  ),
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
              
              const SizedBox(width: 12),
              
              ElevatedButton(
                onPressed: _carrito.isNotEmpty && !_isLoading ? _procesarVenta : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Procesar Venta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
