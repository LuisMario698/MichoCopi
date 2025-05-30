class CategoriaMp {
  final int? id;
  final String nombre;
  final bool conCaducidad;

  CategoriaMp({this.id, required this.nombre, this.conCaducidad = false});

  factory CategoriaMp.fromJson(Map<String, dynamic> json) {
    return CategoriaMp(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      conCaducidad: json['conCaducidad'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'conCaducidad': conCaducidad,
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    return {'nombre': nombre, 'conCaducidad': conCaducidad};
  }

  CategoriaMp copyWith({int? id, String? nombre, bool? conCaducidad}) {
    return CategoriaMp(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      conCaducidad: conCaducidad ?? this.conCaducidad,
    );
  }

  // Métodos de validación
  String? validarNombre() {
    if (nombre.trim().isEmpty) {
      return 'El nombre de la categoría es requerido';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  // Método para validar todos los campos
  List<String> validar() {
    List<String> errores = [];

    String? errorNombre = validarNombre();
    if (errorNombre != null) errores.add(errorNombre);

    return errores;
  }

  // Método para verificar si la categoría es válida
  bool get esValida => validar().isEmpty;

  @override
  String toString() {
    return 'CategoriaMp(id: $id, nombre: $nombre, conCaducidad: $conCaducidad)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoriaMp &&
        other.id == id &&
        other.nombre == nombre &&
        other.conCaducidad == conCaducidad;
  }

  @override
  int get hashCode => Object.hash(id, nombre, conCaducidad);
}
