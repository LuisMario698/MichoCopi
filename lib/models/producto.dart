class Producto {
  final int? id;
  final String nombre;
  final double precio;
  final int stock;
  final int categoria;
  final int proveedor;
  final DateTime? caducidad;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.categoria,
    required this.proveedor,
    this.caducidad,
  });

  // Constructor para crear desde JSON (para Supabase)
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] as int,
      categoria: json['categoria'] as int,
      proveedor: json['proveedor'] as int,
      caducidad:
          json['caducidad'] != null
              ? DateTime.parse(json['caducidad'] as String)
              : null,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'proveedor': proveedor,
      if (caducidad != null)
        'caducidad': caducidad!.toIso8601String().split('T')[0],
    };
  }

  // Método para crear una copia con modificaciones
  Producto copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? stock,
    int? categoria,
    int? proveedor,
    DateTime? caducidad,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      categoria: categoria ?? this.categoria,
      proveedor: proveedor ?? this.proveedor,
      caducidad: caducidad ?? this.caducidad,
    );
  }

  @override
  String toString() {
    return 'Producto(id: $id, nombre: $nombre, precio: $precio, stock: $stock, categoria: $categoria, proveedor: $proveedor, caducidad: $caducidad)';
  }
}

// Modelo para Categoría de Producto
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

  @override
  String toString() {
    return 'Categoria(id: $id, nombre: $nombre, conCaducidad: $conCaducidad)';
  }
}

// Modelo para Proveedor
class Proveedor {
  final int? id;
  final String nombre;
  final String direccion;
  final int telefono;

  Proveedor({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String,
      telefono: json['telefono'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
    };
  }

  @override
  String toString() {
    return 'Proveedor(id: $id, nombre: $nombre, direccion: $direccion, telefono: $telefono)';
  }
}
