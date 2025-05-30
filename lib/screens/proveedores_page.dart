import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/proveedor_form_panel.dart';
import '../models/proveedor.dart';
import '../models/categoria_proveedor.dart';
import '../services/proveedor_service.dart';
import '../services/categoria_proveedor_service.dart';

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
  Proveedor? _proveedorEditar;

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
            horaApertura: '09:00',
            horaCierre: '18:00',
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

  void _toggleFormulario([Proveedor? proveedor]) {
    setState(() {
      _mostrarFormulario = !_mostrarFormulario;
      _proveedorEditar = _mostrarFormulario ? proveedor : null;
    });
  }

  void _onProveedorCreatedOrUpdated(bool success) {
    if (success) {
      _toggleFormulario();
      _cargarProveedores();
    }
  }

  void _eliminarProveedor(Proveedor proveedor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de advertencia
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.warning_rounded,
                        size: 56,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Título
                const Text(
                  'Confirmar eliminación',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC2185B),
                  ),
                ),
                const SizedBox(height: 16),
                // Mensaje
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '¿Estás seguro de que deseas eliminar al proveedor "${proveedor.nombre}"?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop(); // Cerrar diálogo primero
                          
                          // Mostrar indicador de carga
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFC2185B),
                                ),
                              );
                            },
                          );

                          try {
                            final result = await ProveedorService.eliminar(proveedor.id!);
                            
                            // Cerrar indicador de carga
                            Navigator.of(context).pop();
                            
                            if (result['success']) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Proveedor "${proveedor.nombre}" eliminado exitosamente'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _cargarProveedores();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${result['message']}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            // Cerrar indicador de carga
                            Navigator.of(context).pop();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error inesperado: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_forever, size: 20),
                        label: const Text(
                          'Sí, eliminar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC2185B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageWrapper(
          title: 'Proveedores',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _toggleFormulario(),
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
                              MediaQuery.of(context).size.width > 1400
                                  ? 4
                                  : MediaQuery.of(context).size.width > 1100
                                  ? 3
                                  : MediaQuery.of(context).size.width > 800
                                  ? 2
                                  : 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: MediaQuery.of(context).size.width > 600
                              ? 1.5
                              : 1.3,
                        ),
                        itemCount: _proveedores.where((p) => 
                          _searchQuery.isEmpty || 
                          p.nombre.toLowerCase().contains(_searchQuery.toLowerCase())
                        ).length,
                        padding: const EdgeInsets.all(4),
                        itemBuilder: (context, index) {
                          final proveedor = _proveedores.where((p) => 
                            _searchQuery.isEmpty || 
                            p.nombre.toLowerCase().contains(_searchQuery.toLowerCase())
                          ).toList()[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.all(4),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start, // Cambiado de spaceBetween a start
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
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
                                                FutureBuilder<Map<String, dynamic>>(
                                                  future: CategoriaProveedorService.obtenerCategoriaPorId(proveedor.idCategoriaP),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                                      return Text(
                                                        'Cargando...',
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      );
                                                    }
                                                    
                                                    String nombreCategoria;
                                                    if (snapshot.hasData && snapshot.data!['success']) {
                                                      final categoria = snapshot.data!['data'] as CategoriaProveedor;
                                                      nombreCategoria = categoria.nombre;
                                                    } else {
                                                      nombreCategoria = 'Categoría ${proveedor.idCategoriaP}';
                                                    }
                                                    
                                                    return Text(
                                                      nombreCategoria,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Botones de acción (subidos)
                                          IconButton(
                                            onPressed: () => _toggleFormulario(proveedor),
                                            icon: const Icon(Icons.edit),
                                            tooltip: 'Editar proveedor',
                                            style: IconButton.styleFrom(
                                              foregroundColor: const Color(0xFFC2185B),
                                              backgroundColor: const Color(0xFFC2185B).withOpacity(0.1),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 32,
                                            width: 32,
                                            child: IconButton(
                                              onPressed: () => _eliminarProveedor(proveedor),
                                              icon: const Icon(Icons.delete, size: 18),
                                              tooltip: 'Eliminar proveedor',
                                              style: IconButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                backgroundColor: Colors.red.withOpacity(0.1),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Estado Activo/Inactivo (debajo del header)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: proveedor.estaActivo()
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              proveedor.estaActivo()
                                                ? Icons.check_circle
                                                : Icons.access_time,
                                              size: 12,
                                              color: proveedor.estaActivo()
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              proveedor.estaActivo() ? 'Activo' : 'Inactivo',
                                              style: TextStyle(
                                                color: proveedor.estaActivo()
                                                  ? Colors.green[800]
                                                  : Colors.red[800],
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),

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
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Horario: ${proveedor.horaApertura} - ${proveedor.horaCierre}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
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
                    onTap: () => _toggleFormulario(),
                  ),
                ),
              ],
            ),
          ),
        
        // Formulario de proveedor
        if (_mostrarFormulario)
          ProveedorFormPanel(
            onClose: () => _toggleFormulario(),
            onProveedorCreated: _onProveedorCreatedOrUpdated,
            proveedor: _proveedorEditar,
          ),
      ],
    );
  }
}