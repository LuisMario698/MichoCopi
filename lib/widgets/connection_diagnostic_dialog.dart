import 'package:flutter/material.dart';
import 'package:invmicho/services/supabase_setup.dart';

class ConnectionDiagnosticDialog extends StatefulWidget {
  const ConnectionDiagnosticDialog({super.key});

  @override
  State<ConnectionDiagnosticDialog> createState() => _ConnectionDiagnosticDialogState();
}

class _ConnectionDiagnosticDialogState extends State<ConnectionDiagnosticDialog> {
  bool _isRunning = false;
  Map<String, dynamic>? _diagnosticResult;
  String _currentStep = '';

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _currentStep = 'Iniciando diagnóstico...';
    });

    try {
      setState(() {
        _currentStep = 'Verificando conexión básica...';
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _currentStep = 'Probando conexiones alternativas...';
      });
      
      final result = await SupabaseSetup.fullConnectionDiagnostic();
      
      setState(() {
        _currentStep = 'Diagnóstico completado';
        _diagnosticResult = result;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _currentStep = 'Error durante el diagnóstico';
        _diagnosticResult = {
          'success': false,
          'message': 'Error inesperado',
          'details': e.toString(),
        };
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.network_check,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          const Text('Diagnóstico de Conexión'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isRunning) ...[
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentStep,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ] else if (_diagnosticResult != null) ...[
              _buildDiagnosticResults(),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isRunning) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (_diagnosticResult != null && !_diagnosticResult!['success'])
            ElevatedButton(
              onPressed: _runDiagnostic,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
        ],
      ],
    );
  }

  Widget _buildDiagnosticResults() {
    final result = _diagnosticResult!;
    final isSuccess = result['success'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado general
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSuccess ? Colors.green[200]! : Colors.red[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSuccess ? 'Conexión exitosa' : 'Problemas de conexión detectados',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Detalles del diagnóstico
        if (result.containsKey('basicTest')) ...[
          const Text(
            'Detalles del diagnóstico:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          _buildTestResult('Prueba básica', result['basicTest']),
          
          if (result.containsKey('alternativeTest'))
            _buildTestResult('Prueba alternativa', result['alternativeTest']),
        ] else ...[
          Text(
            result['message'] ?? 'Sin detalles disponibles',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (result['details'] != null) ...[
            const SizedBox(height: 8),
            Text(
              result['details'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],

        // Recomendaciones
        if (result.containsKey('recommendation')) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Recomendación:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  result['recommendation'],
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTestResult(String testName, Map<String, dynamic> testResult) {
    final isSuccess = testResult['success'] == true;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check : Icons.close,
            color: isSuccess ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$testName: ${testResult['message'] ?? 'Sin mensaje'}',
                  style: const TextStyle(fontSize: 13),
                ),
                if (testResult['details'] != null)
                  Text(
                    testResult['details'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
