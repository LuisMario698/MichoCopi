class CarritoItem {
  final int productoId;
  final String nombre;
  final double precio;
  int cantidad;
  final int? stock;

  CarritoItem({
    required this.productoId,
    required this.nombre,
    required this.precio,
    this.cantidad = 1,
    this.stock,
  });

  double get subtotal => precio * cantidad;

  bool get puedeAumentar => stock == null || cantidad < stock!;

  CarritoItem copyWith({
    int? productoId,
    String? nombre,
    double? precio,
    int? cantidad,
    int? stock,
  }) {
    return CarritoItem(
      productoId: productoId ?? this.productoId,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      stock: stock ?? this.stock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'stock': stock,
    };
  }

  factory CarritoItem.fromJson(Map<String, dynamic> json) {
    return CarritoItem(
      productoId: json['producto_id'] ?? 0,
      nombre: json['nombre'] ?? '',
      precio: (json['precio'] ?? 0.0).toDouble(),
      cantidad: json['cantidad'] ?? 1,
      stock: json['stock'],
    );
  }
}
