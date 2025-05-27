import 'package:flutter/material.dart';
import 'package:invmicho/widgets/connection_diagnostic_dialog.dart';

class OfflineBanner extends StatelessWidget {
  final String connectionStatus;
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    required this.connectionStatus,
    this.onRetry,
  });

  bool get isOffline => !connectionStatus.contains('exitosa') && !connectionStatus.contains('Conectado');
  bool get isPartialConnection => connectionStatus.contains('parcial');

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPartialConnection ? Colors.orange[100] : Colors.red[100],
        border: Border(
          bottom: BorderSide(
            color: isPartialConnection ? Colors.orange[300]! : Colors.red[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPartialConnection ? Icons.warning_amber : Icons.cloud_off,
            color: isPartialConnection ? Colors.orange[700] : Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPartialConnection ? 'Conexión limitada' : 'Sin conexión',
                  style: TextStyle(
                    color: isPartialConnection ? Colors.orange[900] : Colors.red[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isPartialConnection 
                    ? 'Usando datos locales. Algunas funciones pueden estar limitadas.'
                    : 'Trabajando en modo offline con datos de prueba.',
                  style: TextStyle(
                    color: isPartialConnection ? Colors.orange[800] : Colors.red[800],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: isPartialConnection ? Colors.orange[700] : Colors.red[700],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showDiagnostic(context),
              icon: const Icon(Icons.network_check, size: 16),
              label: const Text('Diagnóstico', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDiagnostic(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const ConnectionDiagnosticDialog();
      },
    );
  }
}
