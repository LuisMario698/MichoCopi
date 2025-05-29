import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/proveedor_form_panel.dart';
import '../models/proveedor.dart';
import '../services/proveedor_service.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  bool _mostrarFormulario = false;
  bool _isLoading = true;
  List<Proveedor> _proveedores = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  Future<void> _cargarProveedores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final proveedorService = ProveedorService();
      _proveedores = await proveedorService.obtenerTodos();
    } catch (e) {
      // Mostrar un mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar proveedores: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Cargar datos de ejemplo en caso de error
      _proveedores = List.generate(
        5,
        (index) => Proveedor(
          id: index + 1,
          nombre: 'Proveedor ${index + 1}',
          direccion: 'Dirección ${index + 1}',
          telefono: 1000000000 + index,
          idCategoriaP: 1,
          email: 'proveedor${index + 1}@ejemplo.com',
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

  void _onProveedorCreated(bool success) {
    if (success) {
      _toggleFormulario();
      _cargarProveedores();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageWrapper(
          title: 'Proveedores',
          actions: [
            ElevatedButton.icon(
              onPressed: _toggleFormulario,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Proveedor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2185B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
      child: Column(
        children: [
          // Búsqueda
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar proveedores...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de proveedores
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 1200
                        ? 3
                        : MediaQuery.of(context).size.width > 800
                        ? 2
                        : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio:
                    MediaQuery.of(context).size.width > 800 ? 1.5 : 1.2,
              ),
              itemCount: 15, // Placeholder
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header con avatar y nombre
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFC2185B),
                              child: Text(
                                'P${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Proveedor ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'ID: PROV${1000 + index}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Activo',
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Información de contacto
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'proveedor${index + 1}@empresa.com',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+1 (555) ${100 + index}-${1000 + index}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ciudad ${index + 1}, País',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Estadísticas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Productos',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '${15 + index}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Última orden',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '2024-01-${15 + index}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total compras',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '\$${(5000 + index * 500).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFFC2185B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },            ),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Búsqueda
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar proveedores...',
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
              ),
              const SizedBox(height: 16),

              // Lista de proveedores
              Expanded(
                child: _isLoading 
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC2185B),
                      ),
                    )
                  : _proveedores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay proveedores registrados',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _toggleFormulario,
                              icon: const Icon(Icons.add),
                              label: const Text('Registrar proveedor'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC2185B),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 1200
                                  ? 3
                                  : MediaQuery.of(context).size.width > 800
                                  ? 2
                                  : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2,
                        ),
                        itemCount: _proveedores.length,
                        padding: const EdgeInsets.all(4),
                        itemBuilder: (context, index) {
                          final proveedor = _proveedores[index];
                          return Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC2185B).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.business,
                                          size: 24,
                                          color: Color(0xFFC2185B),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              proveedor.nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'ID: ${proveedor.id}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Activo',
                                          style: TextStyle(
                                            color: Colors.green[800],
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Información de contacto
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          proveedor.email ?? 'No disponible',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        proveedor.telefonoFormateado,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          proveedor.direccion,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
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
          
          // Overlay para el formulario (opcional)
          if (_mostrarFormulario)
            Positioned.fill(
              child: Stack(
                children: [
                  // Capa de fondo oscura
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  // Capa de blur
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  // Gesture detector para cerrar
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _toggleFormulario,
                    ),
                  ),
                ],
              ),
            ),
          
          // Formulario de proveedor
          if (_mostrarFormulario)
            ProveedorFormPanel(
              onClose: _toggleFormulario,
              onProveedorCreated: _onProveedorCreated,
            ),
        ],
      ),
    );
  }
}
