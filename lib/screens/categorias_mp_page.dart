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
          child: Card(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Unidad')),
                          DataColumn(label: Text('Factor de Conversión')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows:
                            _categorias.map((categoria) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(categoria.nombre)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed:
                                              () =>
                                                  _toggleFormulario(categoria),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed:
                                              () =>
                                                  _confirmarEliminar(categoria),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
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
