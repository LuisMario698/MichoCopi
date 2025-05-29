import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';

class AcercaDePage extends StatelessWidget {
  const AcercaDePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Acerca de',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desarrolladores',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC2185B),
              ),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1200 
                  ? 4 
                  : MediaQuery.of(context).size.width > 800 
                    ? 3 
                    : MediaQuery.of(context).size.width > 600
                      ? 2
                      : 1,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.85,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final desarrolladores = [
                  {
                    'nombre': 'Miguel Rogelio\nSabori Fernández',
                    'icon': Icons.code,
                    'email': 'miguelsabori616@gmail.com',
                    'telefono': '+52 638 109 4483',
                  },
                  {
                    'nombre': 'Jesús Manuel\nQuintero Aldana',
                    'icon': Icons.architecture,
                  },
                  {
                    'nombre': 'Luis Mario\nSuárez Gutiérrez',
                    'icon': Icons.design_services,
                  },
                  {
                    'nombre': 'Alexa Merary\nZamudio Martín',
                    'icon': Icons.analytics,
                    'rol': 'Analista de Sistemas',
                  },
                ];

                final dev = desarrolladores[index];

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC2185B).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            dev['icon'] as IconData,
                            size: 48,
                            color: const Color(0xFFC2185B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          dev['nombre'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (dev['email'] != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  dev['email'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (dev['telefono'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dev['telefono'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Text(
                    'Sistema de Punto de Venta y Control de Inventario',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '© 2025',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFC2185B),
                      fontWeight: FontWeight.w500,
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