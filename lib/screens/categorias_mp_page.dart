import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/categoria_mp.dart';
import '../services/categoria_mp_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/categoria_mp_form_panel.dart';

class CategoriasMpPage extends StatefulWidget {
  const CategoriasMpPage({super.key});

  @override
  State<CategoriasMpPage> createState() => _CategoriasMpPageState();
}

class _CategoriasMpPageState extends State<CategoriasMpPage> {
  final _categoriaMpService = CategoriaMpService();
  List<CategoriaMp> _categorias = [];
  bool _isLoading = true;
  String? _error;
  bool _mostrarFormulario = false;
  CategoriaMp? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final categorias = await _categoriaMpService.obtenerTodas();
      setState(() {
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleFormulario([CategoriaMp? categoria]) {
    setState(() {
      _mostrarFormulario = !_mostrarFormulario;
      _categoriaSeleccionada = categoria;
    });
  }

  void _onCategoriaCreated(bool success) {
    if (success) {
      _toggleFormulario();
      _cargarCategorias();
    }
  }

  Future<void> _confirmarEliminar(CategoriaMp categoria) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Está seguro de eliminar la categoría ${categoria.nombre}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _categoriaMpService.eliminar(categoria.id!);
        if (mounted) {
          await _cargarCategorias();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría eliminada correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageWrapper(
          title: 'Categorías de Materia Prima',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _toggleFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Categoría'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          childAspectRatio: 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = _categorias[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _toggleFormulario(categoria),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header con icono y acciones
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.category_outlined,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      itemBuilder:
                                          (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Editar'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Eliminar'),
                                                ],
                                              ),
                                            ),
                                          ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _toggleFormulario(categoria);
                                        } else if (value == 'delete') {
                                          _confirmarEliminar(categoria);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Nombre de la categoría
                                Text(
                                  categoria.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // Información adicional
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        categoria.unidad,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'FC: ${categoria.fc}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),

        // Overlay para el formulario
        if (_mostrarFormulario)
          Positioned.fill(
            child: Stack(
              children: [
                // Fondo semitransparente
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
                // Backdrop blur
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Gesture detector para cerrar
                Positioned.fill(
                  child: GestureDetector(onTap: _toggleFormulario),
                ),
              ],
            ),
          ),

        // Panel de formulario
        if (_mostrarFormulario)
          CategoriaMpFormPanel(
            categoria: _categoriaSeleccionada,
            onClose: _toggleFormulario,
            onCategoriaCreated: _onCategoriaCreated,
          ),
      ],
    );
  }
}
