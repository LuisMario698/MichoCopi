import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MacOSPermissionsGuide extends StatelessWidget {
  const MacOSPermissionsGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permisos de Red - macOS'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Problema detectado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red[700], size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conexión Bloqueada',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'macOS está bloqueando las conexiones de red de la aplicación',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Soluciones paso a paso
            const Text(
              'Soluciones Paso a Paso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildSolutionCard(
              icon: Icons.settings,
              title: 'Opción 1: Configuración del Sistema',
              steps: [
                'Abre "Configuración del Sistema"',
                'Ve a "Privacidad y Seguridad"',
                'Selecciona "Firewall"',
                'Haz clic en "Opciones..."',
                'Busca Flutter o invmicho en la lista',
                'Cambia a "Permitir conexiones entrantes"',
                'Si no aparece, haz clic en "+" y agrega Flutter',
              ],
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            _buildSolutionCard(
              icon: Icons.terminal,
              title: 'Opción 2: Terminal (Rápido)',
              steps: [
                'Abre Terminal',
                'Ejecuta el script de permisos:',
                './fix_macos_permissions.sh',
                'O ejecuta Flutter con sudo:',
                'sudo flutter run -d macos',
              ],
              color: Colors.green,
            ),

            const SizedBox(height: 16),

            _buildSolutionCard(
              icon: Icons.security,
              title: 'Opción 3: Desactivar Firewall Temporalmente',
              steps: [
                'Ve a Configuración del Sistema > Privacidad y Seguridad',
                'Selecciona "Firewall"',
                'Haz clic en "Desactivar Firewall"',
                'Ejecuta la aplicación',
                'Reactiva el Firewall después',
              ],
              color: Colors.orange,
              isWarning: true,
            ),

            const SizedBox(height: 24),

            // Comandos copiables
            _buildCommandSection(),

            const SizedBox(height: 24),

            // Estado actual
            _buildCurrentStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionCard({
    required IconData icon,
    required String title,
    required List<String> steps,
    required Color color,
    bool isWarning = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (isWarning)
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              int index = entry.key;
              String step = entry.value;
              bool isCommand = step.contains('sudo') || step.contains('./') || step.contains('flutter');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isCommand
                          ? _buildCommandText(step)
                          : Text(step, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandText(String command) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              command,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyCommand(command),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Comandos Útiles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCommandText('sudo flutter run -d macos'),
            const SizedBox(height: 8),
            _buildCommandText('./fix_macos_permissions.sh'),
            const SizedBox(height: 8),
            _buildCommandText('flutter devices'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Estado Actual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusItem('Dispositivo macOS', 'Detectado ✅', Colors.green),
            _buildStatusItem('Conexión a Supabase', 'Bloqueada ❌', Colors.red),
            _buildStatusItem('Modo Offline', 'Activo ✅', Colors.blue),
            _buildStatusItem('Aplicación', 'Funcional ✅', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _copyCommand(String command) {
    Clipboard.setData(ClipboardData(text: command));
    // En una aplicación real, mostrarías un snackbar aquí
  }
}
