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
      final response = await ProveedorService.obtenerTodos();
      if (response['success']) {
        setState(() {
          _proveedores = response['data'].cast<Proveedor>();
        });
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      // Mostrar un mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar proveedores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Cargar datos de ejemplo en caso de error
      setState(() {
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
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                          children: [                            Icon(
                              Icons.business,
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
                                  // Header con avatar y nombre
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFC2185B),
                                        child: Text(
                                          proveedor.nombre.substring(0, 1).toUpperCase(),
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
                                              proveedor.nombre,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Categoría ${proveedor.idCategoriaP}',
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
                                        proveedor.telefono.toString(),
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
        ),
        
        // Overlay para el formulario
        if (_mostrarFormulario)
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
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
    );
  }
}
