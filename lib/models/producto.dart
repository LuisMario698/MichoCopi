class Producto {
  final int? id;
  final String nombre;
  final double precio;
  final int stock;
  final DateTime? caducidad;
  final int idCategoriaProducto;
  final int? idUsuario;
  final int? idReceta;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.caducidad,
    required this.idCategoriaProducto,
    this.idUsuario,
    this.idReceta,
  });

  // Constructor para crear desde JSON (para Supabase)
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] as int,
      caducidad:
          json['caducidad'] != null
              ? DateTime.parse(json['caducidad'] as String)
              : null,
      idCategoriaProducto: json['id_Categoria_producto'] as int,
      idUsuario: json['id_Usuario'] as int?,
      idReceta: json['id_Receta'] as int?,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      if (caducidad != null)
        'caducidad': caducidad!.toIso8601String().split('T')[0],
      'id_Categoria_producto': idCategoriaProducto,
      if (idUsuario != null) 'id_Usuario': idUsuario,
      if (idReceta != null) 'id_Receta': idReceta,
    };
  }

  // Método para crear una copia con modificaciones
  Producto copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? stock,
    DateTime? caducidad,
    int? idCategoriaProducto,
    int? idUsuario,
    int? idReceta,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      caducidad: caducidad ?? this.caducidad,
      idCategoriaProducto: idCategoriaProducto ?? this.idCategoriaProducto,
      idUsuario: idUsuario ?? this.idUsuario,
      idReceta: idReceta ?? this.idReceta,
    );
  }

  @override
  String toString() {
    return 'Producto(id: $id, nombre: $nombre, precio: $precio, stock: $stock, caducidad: $caducidad, idCategoriaProducto: $idCategoriaProducto, idUsuario: $idUsuario, idReceta: $idReceta)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Producto &&
        other.id == id &&
        other.nombre == nombre &&
        other.precio == precio &&
        other.stock == stock &&
        other.caducidad == caducidad &&
        other.idCategoriaProducto == idCategoriaProducto &&
        other.idUsuario == idUsuario &&
        other.idReceta == idReceta;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nombre,
      precio,
      stock,
      caducidad,
      idCategoriaProducto,
      idUsuario,
      idReceta,
    );  }
}
