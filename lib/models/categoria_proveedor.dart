class CategoriaProveedor {
  final int? id;
  final String nombre;
  final String? descripcion;

  CategoriaProveedor({this.id, required this.nombre, this.descripcion});

  // Constructor para crear desde JSON (para Supabase)
  factory CategoriaProveedor.fromJson(Map<String, dynamic> json) {
    return CategoriaProveedor(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }

  // Método copyWith para crear copias con modificaciones
  CategoriaProveedor copyWith({int? id, String? nombre, String? descripcion}) {
    return CategoriaProveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  // Validaciones
  String? validarNombre() {
    if (nombre.trim().isEmpty) {
      return 'El nombre de la categoría es requerido';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (nombre.trim().length > 50) {
      return 'El nombre no puede exceder 50 caracteres';
    }
    return null;
  }

  String? validarDescripcion() {
    if (descripcion != null && descripcion!.trim().isNotEmpty) {
      if (descripcion!.trim().length > 200) {
        return 'La descripción no puede exceder 200 caracteres';
      }
    }
    return null;
  }

  // Método para validar todos los campos
  List<String> validar() {
    List<String> errores = [];

    String? errorNombre = validarNombre();
    if (errorNombre != null) errores.add(errorNombre);

    String? errorDescripcion = validarDescripcion();
    if (errorDescripcion != null) errores.add(errorDescripcion);

    return errores;
  }

  // Método para verificar si la categoría es válida
  bool get esValida => validar().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoriaProveedor &&
        other.id == id &&
        other.nombre == nombre &&
        other.descripcion == descripcion;
  }

  @override
  int get hashCode {
    return Object.hash(id, nombre, descripcion);
  }

  @override
  String toString() {
    return 'CategoriaProveedor{id: $id, nombre: $nombre, descripcion: $descripcion}';
  }
}
