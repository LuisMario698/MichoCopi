import 'package:flutter/material.dart';
import 'side_menu_widget.dart';

class ResponsiveLayout extends StatefulWidget {
  final Widget child;
  final String selectedPage;
  final Function(String) onMenuItemSelected;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.selectedPage,
    required this.onMenuItemSelected,
  });

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: !isWideScreen ? _buildAppBar() : null,
      drawer: !isWideScreen ? _buildDrawer() : null,
      body: Row(
        children: [
          // Menú lateral fijo para pantallas grandes
          if (isWideScreen)
            SideMenuWidget(
              onMenuItemSelected: widget.onMenuItemSelected,
              selectedPage: widget.selectedPage,
            ),

          // Contenido principal
          Expanded(
            child: Container(
              margin: EdgeInsets.all(isWideScreen ? 16 : 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isWideScreen ? 12 : 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isWideScreen ? 12 : 8),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFC2185B),
      foregroundColor: Colors.white,
      elevation: 2,
      title: Row(
        children: [
          const Icon(Icons.inventory_2, size: 24),
          const SizedBox(width: 8),
          const Text(
            'INVMICHO',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ],
      ),
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SideMenuWidget(
        onMenuItemSelected: (page) {
          Navigator.of(context).pop(); // Cerrar drawer
          widget.onMenuItemSelected(page);
        },
        selectedPage: widget.selectedPage,
      ),
    );
  }
}

// Widget helper para crear páginas con un título consistente
class PageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const PageWrapper({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la página
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isWideScreen ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC2185B),
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),

        // Contenido de la página
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isWideScreen ? 24 : 16),
            child: child,
          ),
        ),
      ],
    );
  }
}
