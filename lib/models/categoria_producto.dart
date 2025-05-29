class Categoria {
  final int? id;
  final String nombre;
  final bool conCaducidad;

  Categoria({
    this.id,
    required this.nombre,
    required this.conCaducidad,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
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

  Categoria copyWith({
    int? id,
    String? nombre,
    bool? conCaducidad,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      conCaducidad: conCaducidad ?? this.conCaducidad,
    );
  }

  @override
  String toString() {
    return 'Categoria(id: $id, nombre: $nombre, conCaducidad: $conCaducidad)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria &&
        other.id == id &&
        other.nombre == nombre &&
        other.conCaducidad == conCaducidad;
  }

  @override
  int get hashCode {
    return Object.hash(id, nombre, conCaducidad);
  }
}
