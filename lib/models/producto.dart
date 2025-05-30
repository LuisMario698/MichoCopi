class Producto {
  final int? id;
  final String nombre;
  final double precio;
  final int idCategoriaProducto;
  final int? idUsuario;
  final int? idReceta;
  final String? tamano;
  final int? stock;
  final DateTime? fechaCaducidad;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.idCategoriaProducto,
    this.idUsuario,
    this.idReceta,
    this.tamano,
    this.stock,
    this.fechaCaducidad, // Se mantiene por compatibilidad con datos existentes
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      idCategoriaProducto: (json['id_Categoria_producto'] as num).toInt(),
      idUsuario:
          json['id_Usuario'] != null
              ? (json['id_Usuario'] as num).toInt()
              : null,
      idReceta:
          json['id_Receta'] != null ? (json['id_Receta'] as num).toInt() : null,
      tamano: json['tamaño'] as String?,
      stock: json['stock'] != null ? (json['stock'] as num).toInt() : null,
      fechaCaducidad: json['fecha_caducidad'] != null 
          ? DateTime.parse(json['fecha_caducidad'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'precio': precio,
      'id_Categoria_producto': idCategoriaProducto,
      if (idUsuario != null) 'id_Usuario': idUsuario,
      if (idReceta != null) 'id_Receta': idReceta,
      if (tamano != null) 'tamaño': tamano,
      if (stock != null) 'stock': stock,
      if (fechaCaducidad != null) 'fecha_caducidad': fechaCaducidad!.toIso8601String().split('T')[0],
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'nombre': nombre,
      'precio': precio,
      'id_Categoria_producto': idCategoriaProducto,
      if (idUsuario != null) 'id_Usuario': idUsuario,
      if (idReceta != null) 'id_Receta': idReceta,
      if (tamano != null) 'tamaño': tamano,
      if (stock != null) 'stock': stock,
      if (fechaCaducidad != null) 'fecha_caducidad': fechaCaducidad!.toIso8601String().split('T')[0],
    };
  }

  Producto copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? idCategoriaProducto,
    int? idUsuario,
    int? idReceta,
    String? tamano,
    int? stock,
    DateTime? fechaCaducidad,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      idCategoriaProducto: idCategoriaProducto ?? this.idCategoriaProducto,
      idUsuario: idUsuario ?? this.idUsuario,
      idReceta: idReceta ?? this.idReceta,
      tamano: tamano ?? this.tamano,
      stock: stock ?? this.stock,
      fechaCaducidad: fechaCaducidad ?? this.fechaCaducidad,
    );
  }

  // Helper method to check if product has a recipe
  bool get tieneReceta => idReceta != null;

  // Validation methods
  String? validarNombre() {
    if (nombre.trim().isEmpty) {
      return 'El nombre del producto es requerido';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (nombre.trim().length > 255) {
      return 'El nombre no puede exceder 255 caracteres';
    }
    return null;
  }

  String? validarPrecio() {
    if (precio <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    if (precio > 999999.99) {
      return 'El precio no puede exceder 999,999.99';
    }
    return null;
  }

  String? validarCategoria() {
    if (idCategoriaProducto <= 0) {
      return 'Debe seleccionar una categoría válida';
    }
    return null;
  }

  // Method to validate all fields
  List<String> validar() {
    List<String> errores = [];

    String? errorNombre = validarNombre();
    if (errorNombre != null) errores.add(errorNombre);

    String? errorPrecio = validarPrecio();
    if (errorPrecio != null) errores.add(errorPrecio);

    String? errorCategoria = validarCategoria();
    if (errorCategoria != null) errores.add(errorCategoria);

    return errores;
  }

  @override
  String toString() {
    return 'Producto(id: $id, nombre: $nombre, precio: $precio, idCategoriaProducto: $idCategoriaProducto, idUsuario: $idUsuario, idReceta: $idReceta, tamano: $tamano, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Producto &&
        other.id == id &&
        other.nombre == nombre &&
        other.precio == precio &&
        other.idCategoriaProducto == idCategoriaProducto &&
        other.idUsuario == idUsuario &&
        other.idReceta == idReceta &&
        other.tamano == tamano &&
        other.stock == stock;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nombre.hashCode ^
        precio.hashCode ^
        idCategoriaProducto.hashCode ^
        idUsuario.hashCode ^
        idReceta.hashCode ^
        tamano.hashCode ^
        stock.hashCode;
  }
}
