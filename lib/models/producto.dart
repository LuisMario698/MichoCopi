class Producto {
  final int? id;
  final String nombre;
  final double precio;
  final DateTime? caducidad;
  final int idCategoriaProducto;
  final int? idUsuario;
  final int? idReceta;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    this.caducidad,
    required this.idCategoriaProducto,
    this.idUsuario,
    this.idReceta,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      caducidad: json['caducidad'] != null ? DateTime.parse(json['caducidad']) : null,
      idCategoriaProducto: (json['id_Categoria_producto'] as num).toInt(),
      idUsuario: json['id_Usuario'] != null ? (json['id_Usuario'] as num).toInt() : null,
      idReceta: json['id_Receta'] != null ? (json['id_Receta'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'precio': precio,
      if (caducidad != null) 'caducidad': caducidad!.toIso8601String().split('T')[0],
      'id_Categoria_producto': idCategoriaProducto,
      if (idUsuario != null) 'id_Usuario': idUsuario,
      if (idReceta != null) 'id_Receta': idReceta,
    };
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

  Producto copyWith({
    int? id,
    String? nombre,
    double? precio,
    DateTime? caducidad,
    int? idCategoriaProducto,
    int? idUsuario,
    int? idReceta,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      caducidad: caducidad ?? this.caducidad,
      idCategoriaProducto: idCategoriaProducto ?? this.idCategoriaProducto,
      idUsuario: idUsuario ?? this.idUsuario,
      idReceta: idReceta ?? this.idReceta,
    );
  }
}
