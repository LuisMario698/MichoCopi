import 'package:flutter/material.dart';
import '../models/materia_prima.dart';
import '../services/materia_prima_service.dart';
import '../widgets/responsive_layout.dart';
import '../services/categoria_mp_service.dart';
import '../widgets/materia_prima_form_panel.dart';
import '../widgets/corte_diario_modal.dart';
import '../services/corte_inventario_service.dart';

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
  bool _corteActivo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMateriasPrimas();
    _verificarCorteActivo();
  }

  Future<void> _verificarCorteActivo() async {
    try {
      final corte = await CorteInventarioService().obtenerCorteActivo();
      setState(() {
        _corteActivo = corte != null;
      });
    } catch (e) {
      print('Error al verificar corte activo: $e');
    }
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

  void _mostrarCorteDiario() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CorteDiarioModal(
          materiasPrimas: _getMateriasPrimasFiltradas(),
          onCorteStateChanged: (bool hayCorteActivo) {
            setState(() {
              _corteActivo = hayCorteActivo;
            });
          },
        );
      },
    ).then((actualizado) {
      if (actualizado == true) {
        _cargarMateriasPrimas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Corte diario completado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Inventario de Materias Primas',
      actions: _buildActions(),
      child: Column(
        children: [
          _buildInventoryCards(),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 16),
          _buildInventoryTable(),
        ],
      ),
    );
  }

  // Actions
  List<Widget> _buildActions() {
    return [
      // Cut inventory button
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (_corteActivo
                      ? Colors.green[600]!
                      : const Color(0xFFC2185B))
                  .withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: _mostrarCorteDiario,
          icon: Icon(
            _corteActivo ? Icons.done_all : Icons.play_arrow_rounded,
            size: 24,
          ),
          label: Text(
            _corteActivo ? 'Finalizar Corte' : 'Iniciar Corte',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor:
                _corteActivo ? Colors.green[600] : const Color(0xFFC2185B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(180, 50),
            elevation: 0,
          ),
        ),
      ),
      const SizedBox(width: 20),

      // New raw material button
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Color.fromARGB(255, 233, 30, 99),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: () => _mostrarDialogoAgregarMP(context),
          icon: const Icon(
            Icons.add_circle_rounded,
            size: 28,
            color: Colors.white,
          ),
          label: const Text(
            'Nueva Materia Prima',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(220, 54),
            elevation: 0,
          ),
        ),
      ),
    ];
  }

  // Inventory summary cards
  Widget _buildInventoryCards() {
    return Row(
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
            _materiasPrimas.where((mp) => mp.stock < 10).length.toString(),
            Icons.warning,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInventoryCard(
            'Sin Stock',
            _materiasPrimas.where((mp) => mp.stock == 0).length.toString(),
            Icons.remove_circle,
            Colors.red,
          ),
        ),
      ],
    );
  }

  // Filters
  Widget _buildFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar materia prima...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterValue,
                  icon: Icon(Icons.unfold_more, color: Colors.grey[600]),
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  items:
                      ['Todos', 'Stock bajo', 'Sin stock', 'Stock normal']
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getFilterIcon(item),
                                    size: 18,
                                    color: _getFilterColor(item),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(item),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _filterValue = value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Table
  Widget _buildInventoryTable() {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFC2185B),
                    ),
                  ),
                )
                : _error != null
                ? _buildErrorView()
                : Column(
                  children: [
                    _buildTableHeader(),
                    Expanded(
                      child:
                          _getMateriasPrimasFiltradas().isEmpty
                              ? _buildEmptyView()
                              : _buildTableContent(),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay materias primas disponibles',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera materia prima con el botón "Nueva Materia Prima"',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Nombre',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Categoría',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Stock',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildTableContent() {
    return ListView.builder(
      itemCount: _getMateriasPrimasFiltradas().length,
      itemBuilder: (context, index) {
        final mp = _getMateriasPrimasFiltradas()[index];
        return Container(
          decoration: BoxDecoration(
            color: index.isEven ? Colors.grey[50] : Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Row(
                children: [
                  // Nombre
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                mp.stock < 10
                                    ? Colors.red[50]
                                    : mp.stock < 20
                                    ? Colors.orange[50]
                                    : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            mp.stock == 0
                                ? Icons.error_outline
                                : mp.stock < 10
                                ? Icons.warning_amber
                                : Icons.check_circle_outline,
                            size: 18,
                            color:
                                mp.stock < 10
                                    ? Colors.red[400]
                                    : mp.stock < 20
                                    ? Colors.orange[400]
                                    : Colors.green[400],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            mp.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Categoría
                  Expanded(
                    flex: 2,
                    child: FutureBuilder<String>(
                      future: CategoriaMpService().obtenerNombreCategoria(
                        mp.idCategoriaMp,
                      ),
                      builder: (context, snapshot) {
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC2185B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category,
                                    size: 14,
                                    color: const Color(0xFFC2185B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    snapshot.data ?? 'Cargando...',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFC2185B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Stock
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStockColor(mp.stock).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mp.stock == 0
                                ? Icons.report_gmailerrorred
                                : mp.stock < 10
                                ? Icons.warning_amber_rounded
                                : Icons.inventory_2_rounded,
                            size: 14,
                            color: _getStockColor(mp.stock),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${mp.stock}',
                            style: TextStyle(
                              color: _getStockColor(mp.stock),
                              fontSize: 15,
                              fontWeight:
                                  mp.stock < 10
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Acciones
                  SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            color: Colors.blue[600],
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () => _mostrarDialogoEditarMP(context, mp),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red[600],
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () => _confirmarEliminar(context, mp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInventoryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
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

  Future<void> _mostrarDialogoAjustarStock(
    BuildContext context,
    MateriaPrima mp,
  ) async {
    final stockController = TextEditingController(text: mp.stock.toString());
    String? errorText;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Ajustar Stock: ${mp.nombre}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: stockController,
                    decoration: InputDecoration(
                      labelText: 'Nuevo stock',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.inventory_2),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        errorText = null;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final nuevoStock = double.tryParse(stockController.text);
                      if (nuevoStock == null) {
                        setState(() {
                          errorText = 'Ingrese un número válido';
                        });
                        return;
                      }
                      if (nuevoStock < 0) {
                        setState(() {
                          errorText = 'El stock no puede ser negativo';
                        });
                        return;
                      }

                      await _materiaPrimaService.actualizarStock(
                        mp.id!,
                        nuevoStock,
                      );
                      Navigator.pop(context);
                      await _cargarMateriasPrimas();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stock actualizado correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        errorText = 'Error al actualizar stock: $e';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper methods for filter functionality
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Stock bajo':
        return Icons.warning_amber_rounded;
      case 'Sin stock':
        return Icons.remove_circle_outline;
      case 'Stock normal':
        return Icons.check_circle_outline;
      default:
        return Icons.filter_list;
    }
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Stock bajo':
        return Colors.orange;
      case 'Sin stock':
        return Colors.red;
      case 'Stock normal':
        return Colors.green;
      default:
        return Colors.grey[700]!;
    }
  }

  Color _getStockColor(int stock) {
    if (stock == 0) {
      return Colors.red;
    } else if (stock < 10) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
