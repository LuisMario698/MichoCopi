class Compras {
  final int? id;
  final int? idProveedor;
  final int? idMp;
  final double total;
  final DateTime fecha;
  final int? idUsuario;

  Compras({
    this.id,
    this.idProveedor,
    this.idMp,
    required this.total,
    required this.fecha,
    this.idUsuario,
  });

  // Constructor para crear desde JSON (para Supabase)
  factory Compras.fromJson(Map<String, dynamic> json) {
    return Compras(
      id: json['id'] as int?,
      idProveedor: json['id_Proveedor'] as int?,
      idMp: json['id_mp'] as int?,
      total: (json['total'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
      idUsuario: json['id_Usuario'] as int?,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (idProveedor != null) 'id_Proveedor': idProveedor,
      if (idMp != null) 'id_mp': idMp,
      'total': total,
      'fecha': fecha.toIso8601String(),
      if (idUsuario != null) 'id_Usuario': idUsuario,
    };
  }

  // Método copyWith para crear copias con modificaciones
  Compras copyWith({
    int? id,
    int? idProveedor,
    int? idMp,
    double? total,
    DateTime? fecha,
    int? idUsuario,
  }) {
    return Compras(
      id: id ?? this.id,
      idProveedor: idProveedor ?? this.idProveedor,
      idMp: idMp ?? this.idMp,
      total: total ?? this.total,
      fecha: fecha ?? this.fecha,
      idUsuario: idUsuario ?? this.idUsuario,
    );
  }

  // Métodos de validación
  String? validarTotal() {
    if (total <= 0) {
      return 'El total debe ser mayor a 0';
    }
    if (total > 999999.99) {
      return 'El total no puede exceder \$999,999.99';
    }
    return null;
  }

  String? validarFecha() {
    if (fecha.isAfter(DateTime.now().add(Duration(days: 1)))) {
      return 'La fecha no puede ser en el futuro';
    }
    return null;
  }

  String? validarIdMp() {
    if (idMp != null && idMp! <= 0) {
      return 'El ID de materia prima debe ser válido';
    }
    return null;
  }

  String? validarIdProveedor() {
    if (idProveedor != null && idProveedor! <= 0) {
      return 'El ID de proveedor debe ser válido';
    }
    return null;
  }

  String? validarIdUsuario() {
    if (idUsuario != null && idUsuario! <= 0) {
      return 'El ID de usuario debe ser válido';
    }
    return null;
  }

  // Método para validar todos los campos
  List<String> validar() {
    List<String> errores = [];
    
    String? errorTotal = validarTotal();
    if (errorTotal != null) errores.add(errorTotal);
    
    String? errorFecha = validarFecha();
    if (errorFecha != null) errores.add(errorFecha);
    
    String? errorIdMp = validarIdMp();
    if (errorIdMp != null) errores.add(errorIdMp);
    
    String? errorIdProveedor = validarIdProveedor();
    if (errorIdProveedor != null) errores.add(errorIdProveedor);
    
    String? errorIdUsuario = validarIdUsuario();
    if (errorIdUsuario != null) errores.add(errorIdUsuario);
    
    return errores;
  }

  // Método para verificar si la compra es válida
  bool get esValida => validar().isEmpty;

  // Getters útiles
  String get totalFormateado => '\$${total.toStringAsFixed(2)}';
  
  String get fechaFormateada {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  String toString() {
    return 'Compras(id: $id, idProveedor: $idProveedor, idMp: $idMp, total: $total, fecha: $fecha, idUsuario: $idUsuario)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Compras &&
        other.id == id &&
        other.idProveedor == idProveedor &&
        other.idMp == idMp &&
        other.total == total &&
        other.fecha == fecha &&
        other.idUsuario == idUsuario;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      idProveedor,
      idMp,
      total,
      fecha,
      idUsuario,
    );
  }
}
