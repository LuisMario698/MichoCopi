import 'package:flutter/material.dart';
import 'package:invmicho/services/auth_service.dart';

class SideMenuWidget extends StatefulWidget {
  final Function(String) onMenuItemSelected;
  final String selectedPage;

  const SideMenuWidget({
    super.key,
    required this.onMenuItemSelected,
    required this.selectedPage,
  });

  @override
  State<SideMenuWidget> createState() => _SideMenuWidgetState();
}

class _SideMenuWidgetState extends State<SideMenuWidget> {
  final Color primaryColor = const Color(0xFFC2185B);
  bool _isNavigating = false;

  void _handleNavigation(String page) {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    widget.onMenuItemSelected(page);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Container(
      width: isWideScreen ? 250 : 200,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con Logo
          Container(
            height: isWideScreen ? 120 : 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2,
                  size: isWideScreen ? 40 : 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'INVMICHO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWideScreen ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Menú Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  page: 'dashboard',
                  isWideScreen: isWideScreen,
                ),
                _buildMenuItem(
                  icon: Icons.point_of_sale,
                  title: 'Ventas',
                  page: 'ventas',
                  isWideScreen: isWideScreen,
                ),
                _buildMenuItem(
                  icon: Icons.category,
                  title: 'Productos',
                  page: 'productos',
                  isWideScreen: isWideScreen,
                ),
                _buildMenuItem(
                  icon: Icons.inventory,
                  title: 'Inventario',
                  page: 'inventario',
                  isWideScreen: isWideScreen,
                ),
                _buildMenuItem(
                  icon: Icons.business,
                  title: 'Proveedores',
                  page: 'proveedores',
                  isWideScreen: isWideScreen,
                ),
                _buildMenuItem(
                  icon: Icons.assessment,
                  title: 'Reportes',
                  page: 'reportes',
                  isWideScreen: isWideScreen,
                ),
                const SizedBox(height: 20),
                const Divider(
                  color: Colors.grey,
                  thickness: 0.5,
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'Acerca de',
                  page: 'acerca-de',
                  isWideScreen: isWideScreen,
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Configuraciones',
                  page: 'configuraciones',
                  isWideScreen: isWideScreen,
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildLogoutButton(isWideScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String page,
    required bool isWideScreen,
  }) {
    final bool isSelected = widget.selectedPage == page;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isNavigating ? null : () => _handleNavigation(page),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 16 : 12,
              vertical: isWideScreen ? 12 : 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border:
                  isSelected
                      ? Border(right: BorderSide(color: primaryColor, width: 3))
                      : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: isWideScreen ? 22 : 20,
                  color: isSelected ? primaryColor : Colors.grey[600],
                ),
                if (isWideScreen) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? primaryColor : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? primaryColor : Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool isWideScreen) {
    return Container(
      width: double.infinity,
      child: Material(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isNavigating ? null : () => _showLogoutDialog(),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 16 : 12,
              vertical: isWideScreen ? 12 : 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  size: isWideScreen ? 22 : 20,
                  color: Colors.red[600],
                ),
                if (isWideScreen) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[600],
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  Text(
                    'Salir',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    if (_isNavigating) return;

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
                await AuthService.cerrarSesion();
                if (context.mounted) {
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
}
