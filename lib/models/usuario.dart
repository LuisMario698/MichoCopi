import 'tipo_usuario.dart';

class Usuario {
  final int? id;
  final String nombre;
  final String password;
  final int tipo;
  final DateTime? fechaCreacion;
  final TipoUsuario? tipoUsuario;

  Usuario({
    this.id,
    required this.nombre,
    required this.password,
    required this.tipo,
    this.fechaCreacion,
    this.tipoUsuario,
  });
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      password: json['password'] as String,
      tipo: json['tipo'] as int,
      fechaCreacion:
          json['fecha_creacion'] != null
              ? DateTime.parse(json['fecha_creacion'] as String)
              : null,
      tipoUsuario:
          json['tipo_usuario'] != null
              ? TipoUsuario.fromJson(
                json['tipo_usuario'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'password': password,
      'tipo': tipo,
    };

    if (id != null) {
      data['id'] = id;
    }

    if (fechaCreacion != null) {
      data['fecha_creacion'] = fechaCreacion!.toIso8601String();
    }

    return data;
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'nombre': nombre,
      'password': password,
      'tipo': tipo,
      if (fechaCreacion != null)
        'fecha_creacion': fechaCreacion!.toIso8601String().split('T')[0],
    };
  }

  Usuario copyWith({
    int? id,
    String? nombre,
    String? password,
    int? tipo,
    DateTime? fechaCreacion,
    TipoUsuario? tipoUsuario,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      password: password ?? this.password,
      tipo: tipo ?? this.tipo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
    );
  }

  String? validarNombre() {
    if (nombre.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? validarPassword() {
    if (password.trim().isEmpty) {
      return 'La contraseña es requerida';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? validarTipo() {
    if (tipo <= 0) {
      return 'Debe seleccionar un tipo de usuario válido';
    }
    return null;
  }

  List<String> validar() {
    List<String> errores = [];

    String? errorNombre = validarNombre();
    if (errorNombre != null) errores.add(errorNombre);

    String? errorPassword = validarPassword();
    if (errorPassword != null) errores.add(errorPassword);

    String? errorTipo = validarTipo();
    if (errorTipo != null) errores.add(errorTipo);

    return errores;
  }

  @override
  String toString() {
    return 'Usuario{id: $id, nombre: $nombre, tipo: $tipo, fechaCreacion: $fechaCreacion}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario &&
        other.id == id &&
        other.nombre == nombre &&
        other.password == password &&
        other.tipo == tipo &&
        other.fechaCreacion == fechaCreacion;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nombre.hashCode ^
        password.hashCode ^
        tipo.hashCode ^
        fechaCreacion.hashCode;
  }
}
