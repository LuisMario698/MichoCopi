import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import 'tipo_usuario_service.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;
  static Usuario? _usuarioActual;

  // Getter para obtener el usuario actual
  static Usuario? get usuarioActual => _usuarioActual;

  // Verificar si hay usuario logueado
  static bool get isLoggedIn =>
      _usuarioActual !=
      null; // Función para hashear contraseñas (desactivada para esta implementación)
  // No estamos usando hash para simplificar el login con la base de datos actual
  static String _hashPassword(String password) {
    // Devuelve la contraseña sin hashear para coincidir con la base de datos actual
    return password;
  }

  // Registrar nuevo usuario
  static Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String password,
    required int tipo,
  }) async {
    try {
      print('🔐 Iniciando registro de usuario...');

      // Validaciones iniciales
      if (nombre.trim().isEmpty) {
        return {'success': false, 'message': 'El nombre es requerido'};
      }

      if (nombre.trim().length < 2) {
        return {
          'success': false,
          'message': 'El nombre debe tener al menos 2 caracteres',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'La contraseña debe tener al menos 6 caracteres',
        };
      }

      if (tipo <= 0) {
        return {
          'success': false,
          'message': 'Debe seleccionar un tipo de usuario válido',
        };
      }

      // Verificar que el tipo de usuario existe
      var tipoResult = await TipoUsuarioService.obtenerTipoUsuarioPorId(tipo);
      if (!tipoResult['success']) {
        return {
          'success': false,
          'message': 'El tipo de usuario seleccionado no existe',
        };
      } // Verificar si ya existe un usuario con el mismo nombre
      final existeResponse =
          await _client
              .from('Usuarios')
              .select('id')
              .eq('nombre', nombre.trim())
              .maybeSingle();

      if (existeResponse != null) {
        return {
          'success': false,
          'message': 'Ya existe un usuario con ese nombre',
        };
      }

      // Hashear la contraseña
      String passwordHash = _hashPassword(password);

      // Crear el nuevo usuario
      final nuevoUsuario = Usuario(
        nombre: nombre.trim(),
        password: passwordHash,
        tipo: tipo,
        fechaCreacion: DateTime.now(),
      );

      // Insertar en la base de datos
      final response =
          await _client
              .from('Usuarios')
              .insert(nuevoUsuario.toJson())
              .select()
              .single();

      Usuario usuarioCreado = Usuario.fromJson(response);

      print('✅ Usuario registrado exitosamente: ${usuarioCreado.nombre}');

      return {
        'success': true,
        'message': 'Usuario registrado exitosamente',
        'data': usuarioCreado,
      };
    } catch (e) {
      print('❌ Error al registrar usuario: $e');
      return {
        'success': false,
        'message': 'Error al registrar usuario: ${e.toString()}',
      };
    }
  }

  // Iniciar sesión
  static Future<Map<String, dynamic>> iniciarSesion({
    required String nombre,
    required String password,
  }) async {
    try {
      print('🔑 Iniciando sesión...');

      // Validaciones básicas
      if (nombre.trim().isEmpty) {
        return {
          'success': false,
          'message': 'El nombre de usuario es requerido',
        };
      }

      if (password.isEmpty) {
        return {'success': false, 'message': 'La contraseña es requerida'};
      }

      print(
        '🔍 Buscando usuario con nombre: ${nombre.trim()}',
      ); // No usar hash para comparar, ya que la contraseña en la BD no está hasheada
      final response =
          await _client
              .from('Usuarios')
              .select()
              .eq('nombre', nombre.trim())
              .maybeSingle();

      if (response == null) {
        print('❌ Usuario no encontrado');
        return {'success': false, 'message': 'Nombre de usuario no encontrado'};
      }

      print('📋 Usuario encontrado, verificando contraseña');

      // Verificar contraseña manualmente (sin hash)
      if (response['password'] != password) {
        print('❌ Contraseña incorrecta');
        return {'success': false, 'message': 'Contraseña incorrecta'};
      }

      // Crear el objeto usuario desde la respuesta
      Usuario usuario = Usuario.fromJson(response);

      // Guardar usuario actual
      _usuarioActual = usuario;

      print('✅ Sesión iniciada exitosamente para: ${usuario.nombre}');

      return {
        'success': true,
        'message': 'Sesión iniciada exitosamente',
        'data': usuario,
      };
    } catch (e) {
      print('❌ Error al iniciar sesión: $e');
      return {
        'success': false,
        'message': 'Error al iniciar sesión: ${e.toString()}',
      };
    }
  }

  // Cerrar sesión
  static Future<void> cerrarSesion() async {
    print('🚪 Cerrando sesión...');
    _usuarioActual = null;
    print('✅ Sesión cerrada exitosamente');
  }

  // Cambiar contraseña
  static Future<Map<String, dynamic>> cambiarContrasena({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    try {
      if (_usuarioActual == null) {
        return {'success': false, 'message': 'No hay usuario logueado'};
      }

      // Validar contraseña nueva
      if (passwordNueva.length < 6) {
        return {
          'success': false,
          'message': 'La nueva contraseña debe tener al menos 6 caracteres',
        };
      }

      // Verificar contraseña actual
      String passwordActualHash = _hashPassword(passwordActual);
      if (_usuarioActual!.password != passwordActualHash) {
        return {
          'success': false,
          'message': 'La contraseña actual es incorrecta',
        };
      }

      // Hashear nueva contraseña
      String passwordNuevaHash = _hashPassword(
        passwordNueva,
      ); // Actualizar en la base de datos
      await _client
          .from('Usuarios')
          .update({'password': passwordNuevaHash})
          .eq('id', _usuarioActual!.id!);

      // Actualizar usuario actual
      _usuarioActual = _usuarioActual!.copyWith(password: passwordNuevaHash);

      print('✅ Contraseña cambiada exitosamente');

      return {'success': true, 'message': 'Contraseña cambiada exitosamente'};
    } catch (e) {
      print('❌ Error al cambiar contraseña: $e');
      return {
        'success': false,
        'message': 'Error al cambiar contraseña: ${e.toString()}',
      };
    }
  } // Verificar si la tabla Usuarios existe

  static Future<bool> verificarTablaUsuarios() async {
    try {
      await _client.from('Usuarios').select('id').limit(1);

      return true;
    } catch (e) {
      print('❌ La tabla Usuarios no existe o no es accesible: $e');
      return false;
    }
  }

  // Obtener usuario por ID con información del tipo
  static Future<Map<String, dynamic>> obtenerUsuarioPorId(int id) async {
    try {
      final response =
          await _client
              .from('Usuarios')
              .select('''
            *,
            tipo_usuario:Tipo_Usuario(
              id,
              nombre,
              descripcion
            )
          ''')
              .eq('id', id)
              .single();

      Usuario usuario = Usuario.fromJson(response);

      return {
        'success': true,
        'message': 'Usuario encontrado',
        'data': usuario,
      };
    } catch (e) {
      print('❌ Error al obtener usuario por ID: $e');
      return {
        'success': false,
        'message': 'Usuario no encontrado',
        'data': null,
      };
    }
  }

  // Obtener todos los usuarios (para administración)
  static Future<Map<String, dynamic>> obtenerTodosLosUsuarios() async {
    try {
      final response = await _client
          .from('Usuarios')
          .select('''
            *,
            tipo_usuario:Tipo_Usuario(
              id,
              nombre,
              descripcion
            )
          ''')
          .order('fecha_creacion', ascending: false);

      List<Usuario> usuarios =
          (response as List).map((json) => Usuario.fromJson(json)).toList();

      return {
        'success': true,
        'message': 'Usuarios obtenidos exitosamente',
        'data': usuarios,
      };
    } catch (e) {
      print('❌ Error al obtener usuarios: $e');
      return {
        'success': false,
        'message': 'Error al obtener usuarios: ${e.toString()}',
        'data': <Usuario>[],
      };
    }
  }
}
