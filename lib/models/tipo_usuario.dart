class TipoUsuario {
  final int? id;
  final String nombre;
  final String descripcion;

  TipoUsuario({this.id, required this.nombre, required this.descripcion});

  // Constructor para crear desde JSON (para Supabase)
  factory TipoUsuario.fromJson(Map<String, dynamic> json) {
    return TipoUsuario(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  // Método copyWith para crear copias con modificaciones
  TipoUsuario copyWith({int? id, String? nombre, String? descripcion}) {
    return TipoUsuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  // Validaciones
  String? validarNombre() {
    if (nombre.trim().isEmpty) {
      return 'El nombre del tipo de usuario es requerido';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? validarDescripcion() {
    if (descripcion.trim().isEmpty) {
      return 'La descripción es requerida';
    }
    if (descripcion.trim().length < 5) {
      return 'La descripción debe tener al menos 5 caracteres';
    }
    return null;
  }

  // Validar todo el objeto
  List<String> validar() {
    List<String> errores = [];

    String? errorNombre = validarNombre();
    if (errorNombre != null) errores.add(errorNombre);

    String? errorDescripcion = validarDescripcion();
    if (errorDescripcion != null) errores.add(errorDescripcion);

    return errores;
  }

  @override
  String toString() {
    return 'TipoUsuario{id: $id, nombre: $nombre, descripcion: $descripcion}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TipoUsuario &&
        other.id == id &&
        other.nombre == nombre &&
        other.descripcion == descripcion;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nombre.hashCode ^ descripcion.hashCode;
  }
}
