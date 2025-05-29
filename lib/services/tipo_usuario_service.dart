import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tipo_usuario.dart';

class TipoUsuarioService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Obtener todos los tipos de usuario
  static Future<Map<String, dynamic>> obtenerTiposUsuario() async {
    try {
      print('📝 Obteniendo tipos de usuario...');      final response = await _client
          .from('Tipo_Usuario')
          .select('*')
          .order('nombre');

      if (response.isEmpty) {
        return {
          'success': false,
          'message': 'No se encontraron tipos de usuario',
          'data': <TipoUsuario>[],
        };
      }

      List<TipoUsuario> tiposUsuario = (response as List)
          .map((json) => TipoUsuario.fromJson(json))
          .toList();

      print('✅ Se obtuvieron ${tiposUsuario.length} tipos de usuario');
      
      return {
        'success': true,
        'message': 'Tipos de usuario obtenidos exitosamente',
        'data': tiposUsuario,
      };

    } catch (e) {
      print('❌ Error al obtener tipos de usuario: $e');
      return {
        'success': false,
        'message': 'Error al obtener tipos de usuario: ${e.toString()}',
        'data': <TipoUsuario>[],
      };
    }
  }

  // Obtener tipo de usuario por ID
  static Future<Map<String, dynamic>> obtenerTipoUsuarioPorId(int id) async {
    try {      print('🔍 Buscando tipo de usuario con ID: $id');
        final response = await _client
          .from('Tipo_Usuario')
          .select('*')
          .eq('id', id)
          .single();

      TipoUsuario tipoUsuario = TipoUsuario.fromJson(response);

      print('✅ Tipo de usuario encontrado: ${tipoUsuario.nombre}');
      
      return {
        'success': true,
        'message': 'Tipo de usuario encontrado',
        'data': tipoUsuario,
      };

    } catch (e) {
      print('❌ Error al obtener tipo de usuario por ID: $e');
      return {
        'success': false,
        'message': 'No se encontró el tipo de usuario',
        'data': null,
      };
    }
  }

  // Crear nuevo tipo de usuario (para administración)
  static Future<Map<String, dynamic>> crearTipoUsuario({
    required String nombre,
    required String descripcion,
  }) async {
    try {
      print('➕ Creando nuevo tipo de usuario...');

      // Validaciones iniciales
      if (nombre.trim().isEmpty) {
        return {
          'success': false,
          'message': 'El nombre es requerido',
        };
      }

      if (descripcion.trim().isEmpty) {
        return {
          'success': false,
          'message': 'La descripción es requerida',
        };
      }      // Verificar si ya existe un tipo con ese nombre
      final existeResponse = await _client
          .from('Tipo_Usuario')
          .select('id')
          .eq('nombre', nombre.trim())
          .maybeSingle();

      if (existeResponse != null) {
        return {
          'success': false,
          'message': 'Ya existe un tipo de usuario con ese nombre',
        };
      }

      // Crear el nuevo tipo de usuario
      final nuevoTipo = TipoUsuario(
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
      );

      // Validar el objeto
      List<String> errores = nuevoTipo.validar();
      if (errores.isNotEmpty) {
        return {
          'success': false,
          'message': errores.first,
        };
      }

      final response = await _client
          .from('tipo_usuario')
          .insert(nuevoTipo.toJson())
          .select()
          .single();

      TipoUsuario tipoCreado = TipoUsuario.fromJson(response);

      print('✅ Tipo de usuario creado exitosamente: ${tipoCreado.nombre}');
      
      return {
        'success': true,
        'message': 'Tipo de usuario creado exitosamente',
        'data': tipoCreado,
      };

    } catch (e) {
      print('❌ Error al crear tipo de usuario: $e');
      return {
        'success': false,
        'message': 'Error al crear tipo de usuario: ${e.toString()}',
      };
    }
  }  // Verificar si la tabla Tipo_Usuario existe
  static Future<bool> verificarTablaTipoUsuario() async {
    try {
      await _client
          .from('Tipo_Usuario')
          .select('id')
          .limit(1);
      
      return true;
    } catch (e) {
      print('❌ La tabla Tipo_Usuario no existe o no es accesible: $e');
      return false;
    }
  }

  // Inicializar tipos de usuario básicos (si no existen)
  static Future<Map<String, dynamic>> inicializarTiposBasicos() async {
    try {
      print('🔧 Inicializando tipos de usuario básicos...');

      List<Map<String, String>> tiposBasicos = [
        {
          'nombre': 'Administrador',
          'descripcion': 'Usuario con acceso completo al sistema',
        },
        {
          'nombre': 'Usuario',
          'descripcion': 'Usuario estándar con permisos limitados',
        },
        {
          'nombre': 'Empleado',
          'descripcion': 'Empleado de la empresa con acceso a funciones básicas',
        },
      ];

      List<TipoUsuario> tiposCreados = [];

      for (var tipoData in tiposBasicos) {
        // Verificar si ya existe
        final existeResponse = await _client
            .from('tipo_usuario')
            .select('id')
            .eq('nombre', tipoData['nombre']!)
            .maybeSingle();

        if (existeResponse == null) {
          // No existe, crearlo
          var resultado = await crearTipoUsuario(
            nombre: tipoData['nombre']!,
            descripcion: tipoData['descripcion']!,
          );

          if (resultado['success']) {
            tiposCreados.add(resultado['data']);
          }
        }
      }

      if (tiposCreados.isNotEmpty) {
        print('✅ Se crearon ${tiposCreados.length} tipos de usuario básicos');
        return {
          'success': true,
          'message': 'Tipos de usuario básicos inicializados',
          'data': tiposCreados,
        };
      } else {
        return {
          'success': true,
          'message': 'Los tipos de usuario básicos ya existían',
          'data': <TipoUsuario>[],
        };
      }

    } catch (e) {
      print('❌ Error al inicializar tipos básicos: $e');
      return {
        'success': false,
        'message': 'Error al inicializar tipos básicos: ${e.toString()}',
      };
    }
  }
}
