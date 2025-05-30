import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invmicho/screens/acerca_de_page.dart';
import 'package:invmicho/screens/dashboard_page.dart';
import 'package:invmicho/screens/login_page.dart';
import 'package:invmicho/screens/productos_page.dart';
import 'package:invmicho/screens/proveedores_page.dart';
import 'package:invmicho/screens/reportes_page.dart';
import 'package:invmicho/screens/ventas_page.dart';
import 'package:invmicho/screens/inventario_page.dart';
import 'package:invmicho/services/auth_service.dart';
import 'package:invmicho/services/supabase_setup.dart';
import 'package:invmicho/widgets/responsive_layout.dart';
import 'package:invmicho/widgets/offline_banner.dart';
import 'package:invmicho/widgets/connection_diagnostic_dialog.dart';
import 'package:invmicho/widgets/macos_permissions_guide.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await SupabaseSetup.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invmicho',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC2185B)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFC2185B),
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Configurar rutas
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

// Wrapper para manejar autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificar si hay usuario logueado
    if (AuthService.isLoggedIn) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedPage = 'dashboard';
  String _connectionStatus = 'Conectado a Supabase';

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      // Usar el diagnóstico completo para obtener más información
      final connectionResult = await SupabaseSetup.fullConnectionDiagnostic();

      setState(() {
        if (connectionResult['success']) {
          _connectionStatus = connectionResult['message'];
        } else {
          // Si hay un diagnóstico completo, mostrar información más detallada
          if (connectionResult.containsKey('basicTest') &&
              connectionResult.containsKey('recommendation')) {
            final basicTest = connectionResult['basicTest'];
            _connectionStatus =
                '${basicTest['message']}: ${basicTest['details']}';

            // Mostrar recomendación en consola para debug
            print('💡 Recomendación: ${connectionResult['recommendation']}');
          } else {
            _connectionStatus =
                '${connectionResult['message']}: ${connectionResult['details']}';
          }
        }
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error al verificar conexión: $e';
      });
    }
  }

  void _onMenuItemSelected(String page) {
    if (page == 'logout') {
      _showLogoutDialog();
      return;
    }

    setState(() {
      _selectedPage = page;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Cerrar sesión usando AuthService
                await AuthService.cerrarSesion();
                // Navegar a login y limpiar el stack de navegación
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConnectionDiagnostic() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const ConnectionDiagnosticDialog();
      },
    );
  }

  Future<void> _showMacOSPermissionsGuide() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MacOSPermissionsGuide()),
    );
  }

  Widget _getCurrentPage() {
    switch (_selectedPage) {
      case 'dashboard':
        return const DashboardPage();
      case 'ventas':
        return const VentasPage();
      case 'productos':
        return const ProductosPage();
      case 'inventario':
        return const InventarioPage();
      case 'proveedores':
        return const ProveedoresPage();
      case 'reportes':
        return const ReportesPage();
      case 'acerca-de':
        return const AcercaDePage();
      case 'configuraciones':
        return _buildConfiguracionesPage();
      default:
        return const DashboardPage();
    }
  }

  Widget _buildConfiguracionesPage() {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: const Text(
              'Configuraciones',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC2185B),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estado de la Base de Datos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                _connectionStatus.contains('exitosa') ||
                                        _connectionStatus.contains('Conectado')
                                    ? Icons.check_circle
                                    : _connectionStatus.contains('parcial')
                                    ? Icons.warning
                                    : Icons.error,
                                color:
                                    _connectionStatus.contains('exitosa') ||
                                            _connectionStatus.contains(
                                              'Conectado',
                                            )
                                        ? Colors.green
                                        : _connectionStatus.contains('parcial')
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _connectionStatus,
                                  style: TextStyle(
                                    color:
                                        _connectionStatus.contains('exitosa') ||
                                                _connectionStatus.contains(
                                                  'Conectado',
                                                )
                                            ? Colors.green[700]
                                            : _connectionStatus.contains(
                                              'parcial',
                                            )
                                            ? Colors.orange[700]
                                            : Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _checkConnection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC2185B),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Verificar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _showConnectionDiagnostic,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Diagnóstico'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _showMacOSPermissionsGuide,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Permisos macOS'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sección de pruebas de BD
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pruebas de Base de Datos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OfflineBanner(
          connectionStatus: _connectionStatus,
          onRetry: _checkConnection,
        ),
        Expanded(
          child: ResponsiveLayout(
            selectedPage: _selectedPage,
            onMenuItemSelected: _onMenuItemSelected,
            child: _getCurrentPage(),
          ),
        ),
      ],
    );
  }
}
