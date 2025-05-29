import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _mostrarPassword = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  @override
  void initState() {
    super.initState();

    // Campos limpios sin credenciales de demostración
    _nombreController.text = '';
    _passwordController.text = '';

    // Animación principal
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animación de pulso para el logo
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Iniciar animaciones
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _nombreController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.iniciarSesion(
        nombre: _nombreController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;      if (result['success']) {
        _mostrarMensaje(
          '¡Bienvenido!',
          'Sesión iniciada exitosamente',
          const Color(0xFFC2185B),
          Icons.check_circle,
        );

        // Esperar un momento antes de navegar para mostrar el mensaje
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }      } else {
        _mostrarMensaje(
          'Error de Acceso',
          result['message'] ?? 'Credenciales incorrectas',
          const Color(0xFFD32F2F), // Rojo más suave que combine con la marca
          Icons.error,
        );
      }
    } catch (e) {
      if (!mounted) return;      _mostrarMensaje(
        'Error de Conexión',
        'Verifique su conexión a internet: ${e.toString()}',
        const Color(0xFFFF8F00), // Naranja que combine mejor con la marca
        Icons.warning,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarMensaje(
    String titulo,
    String mensaje,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(mensaje, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
    );
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _passwordController.clear();
    setState(() {
      _mostrarPassword = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 800;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: isWideScreen ? _buildSplitLayout() : _buildMobileLayout(),
          );
        },
      ),
    );
  }

  Widget _buildSplitLayout() {
    return Row(
      children: [
        // Panel izquierdo - Formulario (33%)
        Expanded(
          flex: 33,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF8F9FA)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48.0,
                    vertical: 32.0,
                  ),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompactHeader(),
                          const SizedBox(height: 40),
                          _buildLoginForm(),
                          const SizedBox(height: 24),
                          _buildCompactFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),        
        // Panel derecho - Branding (67%)
        Expanded(
          flex: 67,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,                colors: [
                  Color(0xFFC2185B), // Color principal de la marca
                  Color(0xFF9C1458), // Variante más oscura
                  Color(0xFF7B1142), // Variante más profunda
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBrandingSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFC2185B), // Color principal de la marca
            Color(0xFF9C1458), // Variante más oscura
            Color(0xFF7B1142), // Variante más profunda
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: SlideTransition(
              position: _slideAnimation,              child: Card(
                elevation: 20,
                shadowColor: const Color(0xFFC2185B).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    minHeight: 500,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Color(0xFFF8F9FA)],
                    ),
                  ),
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildLoginForm(),
                      const SizedBox(height: 24),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo animado
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC2185B), Color(0xFF9C1458)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC2185B).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),        const SizedBox(height: 24),

        // Título
        Text(
          'MichoCopi',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFC2185B),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Subtítulo
        Text(
          'Sistema de Inventario',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Descripción
        Text(
          'Acceso para Escritorio',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Campo de usuario
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(
              labelText: 'Usuario',
              hintText: 'Ingrese su nombre de usuario',              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC2185B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, color: const Color(0xFFC2185B)),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: const Color(0xFFC2185B), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingrese su usuario';
              }
              if (value.trim().length < 2) {
                return 'El usuario debe tener al menos 2 caracteres';
              }
              return null;
            },
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _iniciarSesion(),
          ),
          const SizedBox(height: 20),

          // Campo de contraseña
          TextFormField(
            controller: _passwordController,
            obscureText: !_mostrarPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              hintText: 'Ingrese su contraseña',              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC2185B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lock_outline, color: const Color(0xFFC2185B)),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _mostrarPassword = !_mostrarPassword;
                          });
                        },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: const Color(0xFFC2185B), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese su contraseña';
              }
              return null;
            },
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _iniciarSesion(),
          ),
          const SizedBox(height: 32),

          // Botón de acceso
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _iniciarSesion,              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2185B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFC2185B).withOpacity(0.3),
              ),
              child:
                  _isLoading
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Iniciando sesión...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón de limpiar
          TextButton.icon(
            onPressed: _isLoading ? null : _limpiarFormulario,
            icon: Icon(Icons.clear, color: Colors.grey[600]),
            label: Text(
              'Limpiar campos',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCompactHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenido',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Accede a tu heladería',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFC2185B),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
  Widget _buildCompactFooter() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          'v1.0.0 © 2024 Michoacana',
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }
  Widget _buildBrandingSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo principal animado para Michoacana
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.icecream_rounded,
                      size: 100,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 50),

          // Título principal
          Text(
            'Michoacana',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.0,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
          ),          const SizedBox(height: 20),
        ],
      ),
    );
  }
  Widget _buildFooter() {
    return Column(
      children: [
        // Versión y copyright
        Text(
          'Versión 1.0.0  •  © 2024 Michoacana',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
