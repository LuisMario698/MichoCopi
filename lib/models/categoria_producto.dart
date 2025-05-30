class CategoriaProducto {
  final int? id;
  final String nombre;
  final bool conCaducidad;

  CategoriaProducto({
    this.id,
    required this.nombre,
    required this.conCaducidad,
  });
  factory CategoriaProducto.fromJson(Map<String, dynamic> json) {
    return CategoriaProducto(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      nombre: json['nombre'] as String,
      conCaducidad: json['conCaducidad'] == true || json['conCaducidad'] == 'true',
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

  CategoriaProducto copyWith({int? id, String? nombre, bool? conCaducidad}) {
    return CategoriaProducto(
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
    return 'CategoriaProducto(id: $id, nombre: $nombre, conCaducidad: $conCaducidad)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoriaProducto &&
        other.id == id &&
        other.nombre == nombre &&
        other.conCaducidad == conCaducidad;
  }

  @override
  int get hashCode => Object.hash(id, nombre, conCaducidad);
}
