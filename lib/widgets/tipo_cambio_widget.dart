import 'package:flutter/material.dart';
import '../services/tipo_cambio_service.dart';

class TipoCambioWidget extends StatefulWidget {
  const TipoCambioWidget({super.key});

  @override
  State<TipoCambioWidget> createState() => _TipoCambioWidgetState();
}

class _TipoCambioWidgetState extends State<TipoCambioWidget> {
  final TextEditingController _tipoCambioController = TextEditingController();
  double _tipoCambioActual = 17.5;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _cargarTipoCambio();
  }

  Future<void> _cargarTipoCambio() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await TipoCambioService.obtenerTipoCambio();
      if (resultado['success']) {
        setState(() {
          _tipoCambioActual = resultado['data'];
          _tipoCambioController.text = _tipoCambioActual.toString();
        });
      }
    } catch (e) {
      _mostrarError('Error al cargar tipo de cambio: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarTipoCambio() async {
    final nuevoTipo = double.tryParse(_tipoCambioController.text);
    
    if (nuevoTipo == null || nuevoTipo <= 0) {
      _mostrarError('Por favor ingrese un valor válido mayor a 0');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await TipoCambioService.actualizarTipoCambio(nuevoTipo);
      
      if (resultado['success']) {
        setState(() {
          _tipoCambioActual = nuevoTipo;
          _isEditing = false;
        });
        _mostrarExito(resultado['message']);
      } else {
        _mostrarError(resultado['message']);
      }
    } catch (e) {
      _mostrarError('Error al actualizar tipo de cambio: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  void _cancelarEdicion() {
    setState(() {
      _isEditing = false;
      _tipoCambioController.text = _tipoCambioActual.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_exchange, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Tipo de Cambio USD',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_isEditing) ...[
              // Modo edición
              TextField(
                controller: _tipoCambioController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Nuevo tipo de cambio',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  helperText: 'Ingrese el valor en pesos mexicanos por cada dólar',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancelarEdicion,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _actualizarTipoCambio,
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ] else ...[
              // Modo visualización
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tipo de cambio actual:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_tipoCambioActual.toStringAsFixed(2)} MXN = \$1.00 USD',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Editar tipo de cambio',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Este tipo de cambio se usa para convertir pagos en dólares a pesos mexicanos.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tipoCambioController.dispose();
    super.dispose();
  }
}
