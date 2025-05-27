import 'package:flutter/material.dart';

class AppStatusSummary extends StatelessWidget {
  const AppStatusSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Migración Completada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              icon: Icons.category,
              title: 'Migración "Tipo" → "Categoría"',
              description: 'Completada en toda la aplicación',
              status: FeatureStatus.completed,
            ),

            _buildFeatureItem(
              icon: Icons.network_check,
              title: 'Diagnóstico de Conexión',
              description: 'Sistema avanzado de detección de errores',
              status: FeatureStatus.completed,
            ),

            _buildFeatureItem(
              icon: Icons.cloud_off,
              title: 'Modo Offline',
              description: 'Funcionalidad completa sin conexión',
              status: FeatureStatus.completed,
            ),

            _buildFeatureItem(
              icon: Icons.devices,
              title: 'UI Responsive',
              description: 'Overflow corregido, diseño adaptativo',
              status: FeatureStatus.completed,
            ),

            _buildFeatureItem(
              icon: Icons.security,
              title: 'Permisos macOS',
              description: 'Detección y guías de solución',
              status: FeatureStatus.completed,
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
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
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Próximos Pasos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Prueba el sistema de diagnóstico en Configuraciones\n'
                    '• Verifica permisos de red en macOS si es necesario\n'
                    '• Usa el modo offline para todas las funciones\n'
                    '• Lee TROUBLESHOOTING.md para guías detalladas',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required FeatureStatus status,
  }) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case FeatureStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case FeatureStatus.inProgress:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case FeatureStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 20),
        ],
      ),
    );
  }
}

enum FeatureStatus { completed, inProgress, pending }
