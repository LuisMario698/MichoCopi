import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSetup {
  // Configuración de Supabase
  static const String _supabaseUrl = 'https://dwruaswwduegczsgelia.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3cnVhc3d3ZHVlZ2N6c2dlbGlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY1NTUxMTMsImV4cCI6MjA2MjEzMTExM30.OtewBCBvXSIHHJZth4CZxHZ92PF8FBfg0IEB0PKXg4c';

  /// Inicializa la conexión con Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      debug: true, // Cambia a false en producción
    );
  }

  /// Obtiene el cliente de Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// Verifica si Supabase está inicializado
  static bool get isInitialized {
    try {
      // Verifica si el cliente está disponible haciendo una consulta simple
      Supabase.instance.client.auth;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la URL de Supabase
  static String get url => _supabaseUrl;

  /// Prueba la conexión con Supabase
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      // Intenta hacer una consulta simple para verificar la conexión
      await client
          .from('Productos')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      
      return {
        'success': true,
        'message': 'Conexión exitosa a Supabase',
        'details': 'Base de datos accesible'
      };
    } catch (e) {
      // Si falla la primera consulta, intenta una función más simple
      try {
        await client
            .rpc('version')
            .timeout(const Duration(seconds: 3));
        
        return {
          'success': true,
          'message': 'Conexión parcial a Supabase',
          'details': 'Servidor accesible pero pueden haber problemas con las tablas'
        };
      } catch (e2) {
        // Analizar el tipo de error específicamente
        String errorMessage = 'Error de conexión desconocido';
        String errorDetails = e2.toString();
        String errorCode = 'UNKNOWN';
        
        if (errorDetails.contains('SocketException')) {
          if (errorDetails.contains('Operation not permitted')) {
            errorMessage = 'Permisos de red bloqueados';
            errorDetails = 'macOS está bloqueando la conexión de red. Verifica los permisos de la aplicación en Configuración del Sistema > Privacidad y Seguridad > Firewall';
            errorCode = 'PERMISSION_DENIED';
          } else if (errorDetails.contains('Network is unreachable')) {
            errorMessage = 'Red no disponible';
            errorDetails = 'No hay conexión a internet disponible';
            errorCode = 'NETWORK_UNREACHABLE';
          } else {
            errorMessage = 'Error de conexión de red';
            errorDetails = 'Problema con la conexión de red. Verifica tu conexión a internet';
            errorCode = 'SOCKET_ERROR';
          }
        } else if (errorDetails.contains('TimeoutException')) {
          errorMessage = 'Tiempo de espera agotado';
          errorDetails = 'El servidor no responde en el tiempo esperado';
          errorCode = 'TIMEOUT';
        } else if (errorDetails.contains('HandshakeException')) {
          errorMessage = 'Error de certificado SSL';
          errorDetails = 'Problema con el certificado de seguridad del servidor';
          errorCode = 'SSL_ERROR';
        } else if (errorDetails.contains('FormatException')) {
          errorMessage = 'Respuesta inválida del servidor';
          errorDetails = 'El servidor devolvió una respuesta mal formateada';
          errorCode = 'FORMAT_ERROR';
        }
        
        print('🔥 Error detallado de conexión: $e2');
        print('📊 Código de error: $errorCode');
        
        return {
          'success': false,
          'message': errorMessage,
          'details': errorDetails,
          'error': e2.toString(),
          'errorCode': errorCode
        };
      }
    }
  }

  /// Intenta una conexión alternativa con diferentes configuraciones
  static Future<Map<String, dynamic>> attemptAlternativeConnection() async {
    print('🔄 Intentando conexión alternativa...');
    
    try {
      // Intentar con timeout más largo
      await client
          .from('Productos')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 15));
      
      return {
        'success': true,
        'message': 'Conexión exitosa con timeout extendido',
        'details': 'La conexión funciona pero puede ser lenta'
      };
    } catch (e) {
      print('❌ Conexión alternativa falló: $e');
      
      // Intentar solo verificar si el servidor responde
      try {
        final uri = Uri.parse(_supabaseUrl);
        print('🌐 Verificando acceso al dominio: ${uri.host}');
        
        return {
          'success': false,
          'message': 'Servidor Supabase no accesible',
          'details': 'El servidor de Supabase no está respondiendo. Esto puede ser un problema de red, firewall o el servicio puede estar temporalmente no disponible.',
          'errorCode': 'SERVER_UNREACHABLE'
        };
      } catch (e2) {
        return {
          'success': false,
          'message': 'Error crítico de red',
          'details': 'No se puede establecer ningún tipo de conexión de red',
          'errorCode': 'CRITICAL_NETWORK_ERROR'
        };
      }
    }
  }

  /// Diagnóstico completo de conexión
  static Future<Map<String, dynamic>> fullConnectionDiagnostic() async {
    print('🔍 Iniciando diagnóstico completo de conexión...');
    
    // Paso 1: Verificar conexión básica
    final basicTest = await testConnection();
    if (basicTest['success']) {
      return basicTest;
    }
    
    print('⚠️ Conexión básica falló, intentando alternativas...');
    
    // Paso 2: Intentar conexión alternativa
    final alternativeTest = await attemptAlternativeConnection();
    
    // Paso 3: Crear reporte completo
    return {
      'success': false,
      'message': 'Diagnóstico de conexión completado',
      'basicTest': basicTest,
      'alternativeTest': alternativeTest,
      'recommendation': _getConnectionRecommendation(basicTest, alternativeTest),
      'offlineMode': true
    };
  }

  /// Obtiene recomendaciones basadas en los resultados del diagnóstico
  static String _getConnectionRecommendation(Map<String, dynamic> basicTest, Map<String, dynamic> alternativeTest) {
    final basicError = basicTest['errorCode'] ?? '';
    
    switch (basicError) {
      case 'PERMISSION_DENIED':
        return 'Verifica los permisos de red en Configuración del Sistema > Privacidad y Seguridad > Firewall. Permite que la aplicación acceda a la red.';
      case 'NETWORK_UNREACHABLE':
        return 'Verifica tu conexión a internet. Intenta acceder a otros sitios web para confirmar que internet funciona correctamente.';
      case 'TIMEOUT':
        return 'La conexión es muy lenta. Verifica la velocidad de tu internet o intenta conectarte a una red más estable.';
      case 'SSL_ERROR':
        return 'Problema con certificados de seguridad. Esto puede ser un problema temporal del servidor o de tu configuración de red.';
      default:
        return 'Error de conexión general. Verifica tu conexión a internet y los permisos de la aplicación. Si el problema persiste, usa el modo offline.';
    }
  }

  /// Verifica si estamos en modo offline
  static Future<bool> isOfflineMode() async {
    final result = await testConnection();
    return !result['success'];
  }
}
