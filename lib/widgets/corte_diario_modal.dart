import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/materia_prima.dart';
import '../services/corte_inventario_service.dart';
import 'actualizar_stock_dialog.dart';

class CorteDiarioModal extends StatefulWidget {
  final List<MateriaPrima> materiasPrimas;
  final ValueChanged<bool>? onCorteStateChanged;

  const CorteDiarioModal({
    Key? key,
    required this.materiasPrimas,
    this.onCorteStateChanged,
  }) : super(key: key);

  @override
  State<CorteDiarioModal> createState() => _CorteDiarioModalState();
}

class _CorteDiarioModalState extends State<CorteDiarioModal> {
  bool _isLoading = false;
  bool _hayCorteActivo = false;
  Set<MateriaPrima> _materiasPrimasPendientes = {};
  Set<MateriaPrima> _materiasPrimasProcesadas = {};

  @override
  void initState() {
    super.initState();
    _cargarMateriasPrimas();
  }

  Future<void> _cargarMateriasPrimas() async {
    setState(() => _isLoading = true);
    try {
      final corteActivo = await CorteInventarioService().obtenerCorteActivo();
      setState(() {
        _hayCorteActivo = corteActivo != null;
        _materiasPrimasPendientes = widget.materiasPrimas.toSet();
        _materiasPrimasProcesadas = {};
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar materias primas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _iniciarCorte() async {
    setState(() {
      _isLoading = true;
      _hayCorteActivo = true;
    });
    try {
      // Preparar el mapa de stock inicial
      final materiasPrimasMap = {
        for (var mp in widget.materiasPrimas)
          if (mp.id is int) mp.id as int: mp.stock,
      };

      // Iniciar el corte con el stock inicial
      await CorteInventarioService().iniciarCorte(materiasPrimasMap);

      // Notificar al padre del cambio de estado
      widget.onCorteStateChanged?.call(true);
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Corte iniciado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Si hay un error, revertimos el estado local
      setState(() {
        _hayCorteActivo = false;
      });
      // También revertimos el estado en el padre
      widget.onCorteStateChanged?.call(false);
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el modal incluso si hay error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar el corte: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _finalizarCorte() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Crear mapa de IDs y stocks actuales
      final stockFinal = {
        for (var mp in widget.materiasPrimas)
          if (mp.id is int) mp.id as int: mp.stock,
      };

      await CorteInventarioService().finalizarCorte(stockFinal);

      setState(() {
        _hayCorteActivo = false;
        _materiasPrimasPendientes.clear();
      });

      // Notificar al padre del cambio de estado
      widget.onCorteStateChanged?.call(false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Corte finalizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Cerrar el modal después de finalizar
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar el corte: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _actualizarStock(
    MateriaPrima materiaPrima, {
    bool mostrarDialog = true,
  }) async {
    try {
      if (mostrarDialog) {
        final result = await showDialog<bool>(
          context: context,
          builder:
              (context) => ActualizarStockDialog(materiaPrima: materiaPrima),
        );

        if (result != true) return;
      }

      setState(() {
        _materiasPrimasProcesadas.add(materiaPrima);
        _materiasPrimasPendientes.remove(materiaPrima);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar registro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFC2185B),
                    const Color(0xFFC2185B).withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC2185B).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Corte de Inventario',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verifica y actualiza el stock de materias primas',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pendientes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFC2185B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.pending_outlined,
                                  color: Color(0xFFC2185B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pendientes (${_materiasPrimasPendientes.length})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC2185B),
                                    ),
                                  ),
                                  Text(
                                    'Da clic para actualizar el stock',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child:
                              _materiasPrimasPendientes.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 64,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay materias primas pendientes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    children:
                                        _materiasPrimasPendientes.map((mp) {
                                          return _buildPendingItemCard(mp);
                                        }).toList(),
                                  ),
                        ),
                      ],
                    ),
                  ),

                  Container(width: 1, color: Colors.grey[200]),

                  // Procesadas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Procesadas (${_materiasPrimasProcesadas.length})',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Text(
                                    'Stock actualizado correctamente',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child:
                              _materiasPrimasProcesadas.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 64,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay materias primas procesadas',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    children:
                                        _materiasPrimasProcesadas.map((mp) {
                                          return _buildProcessedItemCard(mp);
                                        }).toList(),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Estado del corte',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFC2185B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC2185B),
                            ),
                            children: [
                              TextSpan(
                                text: '${_materiasPrimasProcesadas.length}',
                              ),
                              TextSpan(
                                text: ' / ${widget.materiasPrimas.length}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value:
                              _materiasPrimasProcesadas.length /
                              widget.materiasPrimas.length,
                          backgroundColor: const Color(
                            0xFFC2185B,
                          ).withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFC2185B),
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : () async {
                              if (_hayCorteActivo) {
                                if (_materiasPrimasPendientes.isEmpty) {
                                  await _finalizarCorte();
                                  setState(() {
                                    _hayCorteActivo = false;
                                    _materiasPrimasPendientes =
                                        widget.materiasPrimas.toSet();
                                    _materiasPrimasProcesadas = {};
                                  });
                                }
                              } else {
                                await _iniciarCorte();
                              }
                            },
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(
                              _hayCorteActivo
                                  ? Icons.done_all
                                  : Icons.play_arrow,
                            ),
                    label: Text(
                      _hayCorteActivo ? 'Finalizar Corte' : 'Iniciar Corte',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC2185B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItemCard(MateriaPrima mp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _actualizarStock(mp),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFC2185B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mp.nombre.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFC2185B),
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mp.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Stock actual: ${mp.stock}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _actualizarStock(mp),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Actualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _actualizarStock(mp, mostrarDialog: false),
                tooltip: 'Mover sin cambios',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessedItemCard(MateriaPrima mp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green[100]!),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50]!.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  mp.nombre.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mp.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Stock actualizado: ${mp.stock}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Procesado',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
