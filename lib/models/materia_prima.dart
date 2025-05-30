class MateriaPrima {
  final int? id;
  final String nombre;
  final int idCategoriaMp;
  final int stock;
  final DateTime fechaCreacion;
  final bool seVende;
  final double? siVendePrecio;

  MateriaPrima({
    this.id,
    required this.nombre,
    required this.idCategoriaMp,
    required this.stock,
    required this.fechaCreacion,
    this.seVende = false,
    this.siVendePrecio,
  });  factory MateriaPrima.fromJson(Map<String, dynamic> json) {
    return MateriaPrima(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      nombre: json['nombre'] as String,
      idCategoriaMp: (json['id_Categoria_mp'] as num).toInt(),
      stock: (json['stock'] as num).toInt(),
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      seVende: json['seVende'] as bool? ?? false,
      siVendePrecio: json['siVendePrecio'] != null 
          ? (json['siVendePrecio'] as num).toDouble() 
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'id_Categoria_mp': idCategoriaMp,
      'stock': stock,
      'fecha_creacion': fechaCreacion.toIso8601String().split('T')[0],
      'seVende': seVende,
      if (siVendePrecio != null) 'siVendePrecio': siVendePrecio,
    };
  }
  MateriaPrima copyWith({
    int? id,
    String? nombre,
    int? idCategoriaMp,
    int? stock,
    DateTime? fechaCreacion,
    bool? seVende,
    double? siVendePrecio,
  }) {
    return MateriaPrima(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      idCategoriaMp: idCategoriaMp ?? this.idCategoriaMp,
      stock: stock ?? this.stock,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      seVende: seVende ?? this.seVende,
      siVendePrecio: siVendePrecio ?? this.siVendePrecio,
    );
  }

  // Métodos de validación
  String? validarNombre() {
    if (nombre.trim().isEmpty) {
      return 'El nombre de la materia prima es requerido';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? validarStock() {
    if (stock < 0) {
      return 'El stock no puede ser negativo';
    }
    return null;
  }

  String? validarIdCategoriaMp() {
    if (idCategoriaMp <= 0) {
      return 'Debe seleccionar una categoría válida';
    }
    return null;
  }

  String? validarPrecioVenta() {
    if (seVende && (siVendePrecio == null || siVendePrecio! <= 0)) {
      return 'Si se vende, debe tener un precio mayor a 0';
    }
    return null;
  }

  // Método para validar todos los campos
  List<String> validar() {
    List<String> errores = [];
    
    String? errorNombre = validarNombre();
    if (errorNombre != null) errores.add(errorNombre);
    
    String? errorStock = validarStock();
    if (errorStock != null) errores.add(errorStock);
    
    String? errorCategoria = validarIdCategoriaMp();
    if (errorCategoria != null) errores.add(errorCategoria);
    
    String? errorPrecio = validarPrecioVenta();
    if (errorPrecio != null) errores.add(errorPrecio);
    
    return errores;
  }

  // Método para verificar si la materia prima es válida
  bool get esValida => validar().isEmpty;

  // Métodos de utilidad
  String get stockFormateado => '$stock unidades';
  
  String get precioFormateado {
    if (seVende && siVendePrecio != null) {
      return '\$${siVendePrecio!.toStringAsFixed(2)}';
    }
    return 'No se vende';
  }

  String get fechaFormateada {
    return '${fechaCreacion.day.toString().padLeft(2, '0')}/${fechaCreacion.month.toString().padLeft(2, '0')}/${fechaCreacion.year}';
  }

  @override
  String toString() {
    return 'MateriaPrima(id: $id, nombre: $nombre, idCategoriaMp: $idCategoriaMp, stock: $stock, fechaCreacion: $fechaCreacion, seVende: $seVende, siVendePrecio: $siVendePrecio)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MateriaPrima &&
        other.id == id &&
        other.nombre == nombre &&
        other.idCategoriaMp == idCategoriaMp &&
        other.stock == stock &&
        other.fechaCreacion == fechaCreacion &&
        other.seVende == seVende &&
        other.siVendePrecio == siVendePrecio;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nombre,
      idCategoriaMp,
      stock,
      fechaCreacion,
      seVende,
      siVendePrecio,
    );
  }
}
