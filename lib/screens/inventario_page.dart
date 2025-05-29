import 'package:flutter/material.dart';
import '../models/materia_prima.dart';
import '../services/materia_prima_service.dart';
import '../widgets/responsive_layout.dart';
import '../services/categoria_mp_service.dart';
import '../widgets/materia_prima_form_panel.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final _materiaPrimaService = MateriaPrimaService();
  final _searchController = TextEditingController();
  String _filterValue = 'Todos';
  List<MateriaPrima> _materiasPrimas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMateriasPrimas();
  }

  Future<void> _cargarMateriasPrimas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final materiasPrimas = await _materiaPrimaService.obtenerTodas();
      setState(() {
        _materiasPrimas = materiasPrimas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MateriaPrima> _getMateriasPrimasFiltradas() {
    var materiasFiltered = _materiasPrimas;

    // Aplicar filtro de búsqueda
    if (_searchController.text.isNotEmpty) {
      materiasFiltered =
          materiasFiltered
              .where(
                (mp) => mp.nombre.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();
    }

    // Aplicar filtro de estado
    switch (_filterValue) {
      case 'Stock bajo':
        materiasFiltered =
            materiasFiltered.where((mp) => mp.stock < 10).toList();
        break;
      case 'Sin stock':
        materiasFiltered =
            materiasFiltered.where((mp) => mp.stock == 0).toList();
        break;
      case 'Stock normal':
        materiasFiltered =
            materiasFiltered.where((mp) => mp.stock >= 10).toList();
        break;
    }

    return materiasFiltered;
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Inventario de Materias Primas',
      actions: [
        IconButton(
          icon: const Icon(Icons.category),
          tooltip: 'Gestionar Categorías',
          onPressed: () {
            Navigator.pushNamed(context, '/categorias-mp');
          },
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Implementar reporte de inventario
          },
          icon: const Icon(Icons.download),
          label: const Text('Exportar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _mostrarDialogoAgregarMP(context),
          icon: const Icon(Icons.add),
          label: const Text('Nueva Materia Prima'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: Column(
        children: [
          // Resumen de inventario
          Row(
            children: [
              Expanded(
                child: _buildInventoryCard(
                  'Total Materias Primas',
                  _materiasPrimas.length.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInventoryCard(
                  'Stock Bajo',
                  _materiasPrimas
                      .where((mp) => mp.stock < 10)
                      .length
                      .toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInventoryCard(
                  'Sin Stock',
                  _materiasPrimas
                      .where((mp) => mp.stock == 0)
                      .length
                      .toString(),
                  Icons.remove_circle,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInventoryCard(
                  'Para Venta',
                  _materiasPrimas.where((mp) => mp.seVende).length.toString(),
                  Icons.shopping_cart,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filtros
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar materia prima...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _filterValue,
                    items:
                        ['Todos', 'Stock bajo', 'Sin stock', 'Stock normal']
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _filterValue = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tabla de inventario
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: Center(child: Text('Error: $_error')))
          else
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Materia Prima',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Categoría',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Stock',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Se Vende',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Precio',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 100),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _getMateriasPrimasFiltradas().length,
                        itemBuilder: (context, index) {
                          final mp = _getMateriasPrimasFiltradas()[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(mp.nombre)),
                                Expanded(
                                  child: FutureBuilder(
                                    future: CategoriaMpService().obtenerPorId(
                                      mp.idCategoriaMp,
                                    ),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.data?.nombre ?? '...',
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    mp.stockFormateado,
                                    style: TextStyle(
                                      color:
                                          mp.stock == 0
                                              ? Colors.red
                                              : mp.stock < 10
                                              ? Colors.orange
                                              : null,
                                    ),
                                  ),
                                ),
                                Expanded(child: Text(mp.seVende ? 'Sí' : 'No')),
                                Expanded(child: Text(mp.precioFormateado)),
                                SizedBox(
                                  width: 100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed:
                                            () => _mostrarDialogoEditarMP(
                                              context,
                                              mp,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed:
                                            () =>
                                                _confirmarEliminar(context, mp),
                                      ),
                                    ],
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
            ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoAgregarMP(BuildContext context) async {
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (context) => MateriaPrimaFormPanel(
            onClose: () => Navigator.of(context).pop(),
            onMateriaPrimaCreated: (success) {
              Navigator.of(context).pop();
              if (success) {
                _cargarMateriasPrimas();
              }
            },
          ),
    );
  }

  Future<void> _mostrarDialogoEditarMP(
    BuildContext context,
    MateriaPrima mp,
  ) async {
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (context) => MateriaPrimaFormPanel(
            materiaPrima: mp,
            onClose: () => Navigator.of(context).pop(),
            onMateriaPrimaCreated: (success) {
              Navigator.of(context).pop();
              if (success) {
                _cargarMateriasPrimas();
              }
            },
          ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, MateriaPrima mp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text('¿Está seguro de eliminar ${mp.nombre}?'),
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
        await _materiaPrimaService.eliminar(mp.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Materia prima eliminada')),
          );
          await _cargarMateriasPrimas();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
