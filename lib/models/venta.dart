class Venta {
  final int? id;
  final List<int> idProductos;
  final double total;
  final DateTime fecha;
  final double pago;
  final double cambio;
  final int idUsuario;
  final int? idMpSeVende;
  final String? metodoPago; // Campo adicional del esquema
  final double? tipoCambio; // Campo adicional del esquema
  final String? cliente; // Campo del esquema moderno
  final String? estado; // Campo del esquema moderno

  Venta({
    this.id,
    required this.idProductos,
    required this.total,
    required this.fecha,
    required this.pago,
    required this.cambio,
    required this.idUsuario,
    this.idMpSeVende,
    this.metodoPago,
    this.tipoCambio,
    this.cliente,
    this.estado,
  });
  // Constructor para crear desde JSON (para Supabase)
  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      idProductos:
          json['id_Productos'] != null
              ? List<int>.from(
                (json['id_Productos'] as List).map((e) => (e as num).toInt()),
              )
              : [],
      total: (json['total'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
      pago: json['pago'] != null ? (json['pago'] as num).toDouble() : 0.0,
      cambio: json['cambio'] != null ? (json['cambio'] as num).toDouble() : 0.0,
      idUsuario:
          json['id_Usuario'] != null
              ? (json['id_Usuario'] as num).toInt()
              : (json['usuario_id'] != null
                  ? (json['usuario_id'] as num).toInt()
                  : 0),
      idMpSeVende:
          json['id_mp_seVende'] != null
              ? (json['id_mp_seVende'] as num).toInt()
              : null,
      metodoPago: json['metodo_pago'] as String?,
      tipoCambio:
          json['tipo_cambio'] != null
              ? (json['tipo_cambio'] as num).toDouble()
              : null,
      cliente: json['cliente'] as String?,
      estado: json['estado'] as String?,
    );
  }
  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_Productos': idProductos,
      'total': total,
      'fecha': fecha.toIso8601String(),
      'pago': pago,
      'cambio': cambio,
      'id_Usuario': idUsuario,
      if (idMpSeVende != null) 'id_mp_seVende': idMpSeVende,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (tipoCambio != null) 'tipo_cambio': tipoCambio,
      if (cliente != null) 'cliente': cliente,
      if (estado != null) 'estado': estado,
    };
  }

  // Método especial para insertar (sin ID)
  Map<String, dynamic> toJsonForInsert() {
    return {
      'id_Productos': idProductos,
      'total': total,
      'fecha': fecha.toIso8601String(),
      'pago': pago,
      'cambio': cambio,
      'id_Usuario': idUsuario,
      if (idMpSeVende != null) 'id_mp_seVende': idMpSeVende,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (tipoCambio != null) 'tipo_cambio': tipoCambio,
      if (cliente != null) 'cliente': cliente,
      'estado': estado ?? 'Completada',
    };
  }

  // Método copyWith para crear copias con modificaciones
  Venta copyWith({
    int? id,
    List<int>? idProductos,
    double? total,
    DateTime? fecha,
    double? pago,
    double? cambio,
    int? idUsuario,
    int? idMpSeVende,
    String? metodoPago,
    double? tipoCambio,
    String? cliente,
    String? estado,
  }) {
    return Venta(
      id: id ?? this.id,
      idProductos: idProductos ?? this.idProductos,
      total: total ?? this.total,
      fecha: fecha ?? this.fecha,
      pago: pago ?? this.pago,
      cambio: cambio ?? this.cambio,
      idUsuario: idUsuario ?? this.idUsuario,
      idMpSeVende: idMpSeVende ?? this.idMpSeVende,
      metodoPago: metodoPago ?? this.metodoPago,
      tipoCambio: tipoCambio ?? this.tipoCambio,
      cliente: cliente ?? this.cliente,
      estado: estado ?? this.estado,
    );
  }

  // Métodos de validación
  String? validarIdProductos() {
    if (idProductos.isEmpty) {
      return 'Debe incluir al menos un producto';
    }
    for (int id in idProductos) {
      if (id <= 0) {
        return 'Todos los IDs de productos deben ser válidos';
      }
    }
    return null;
  }

  String? validarTotal() {
    if (total <= 0) {
      return 'El total debe ser mayor a 0';
    }
    if (total > 999999.99) {
      return 'El total no puede exceder \$999,999.99';
    }
    return null;
  }

  String? validarPago() {
    if (pago < total) {
      return 'El pago no puede ser menor al total';
    }
    if (pago > 999999.99) {
      return 'El pago no puede exceder \$999,999.99';
    }
    return null;
  }

  String? validarCambio() {
    double cambioCalculado = pago - total;
    if ((cambio - cambioCalculado).abs() > 0.01) {
      return 'El cambio no coincide con el pago menos el total';
    }
    return null;
  }

  String? validarFecha() {
    if (fecha.isAfter(DateTime.now().add(Duration(days: 1)))) {
      return 'La fecha no puede ser en el futuro';
    }
    return null;
  }

  String? validarIdUsuario() {
    if (idUsuario <= 0) {
      return 'El ID de usuario debe ser válido';
    }
    return null;
  }

  String? validarIdMpSeVende() {
    if (idMpSeVende != null && idMpSeVende! <= 0) {
      return 'El ID de materia prima debe ser válido';
    }
    return null;
  }

  // Método para validar todos los campos
  List<String> validar() {
    List<String> errores = [];

    String? errorProductos = validarIdProductos();
    if (errorProductos != null) errores.add(errorProductos);

    String? errorTotal = validarTotal();
    if (errorTotal != null) errores.add(errorTotal);

    String? errorPago = validarPago();
    if (errorPago != null) errores.add(errorPago);

    String? errorCambio = validarCambio();
    if (errorCambio != null) errores.add(errorCambio);

    String? errorFecha = validarFecha();
    if (errorFecha != null) errores.add(errorFecha);

    String? errorUsuario = validarIdUsuario();
    if (errorUsuario != null) errores.add(errorUsuario);

    String? errorMpSeVende = validarIdMpSeVende();
    if (errorMpSeVende != null) errores.add(errorMpSeVende);

    return errores;
  }

  // Método para verificar si la venta es válida
  bool get esValida => validar().isEmpty;

  // Getters útiles
  String get totalFormateado => '\$${total.toStringAsFixed(2)}';
  String get pagoFormateado => '\$${pago.toStringAsFixed(2)}';
  String get cambioFormateado => '\$${cambio.toStringAsFixed(2)}';

  String get fechaFormateada {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  int get cantidadProductos => idProductos.length;
  @override
  String toString() {
    return 'Venta(id: $id, idProductos: $idProductos, total: $total, fecha: $fecha, pago: $pago, cambio: $cambio, idUsuario: $idUsuario, idMpSeVende: $idMpSeVende, metodoPago: $metodoPago, tipoCambio: $tipoCambio, cliente: $cliente, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Venta &&
        other.id == id &&
        _listEquals(other.idProductos, idProductos) &&
        other.total == total &&
        other.fecha == fecha &&
        other.pago == pago &&
        other.cambio == cambio &&
        other.idUsuario == idUsuario &&
        other.idMpSeVende == idMpSeVende &&
        other.metodoPago == metodoPago &&
        other.tipoCambio == tipoCambio &&
        other.cliente == cliente &&
        other.estado == estado;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      Object.hashAll(idProductos),
      total,
      fecha,
      pago,
      cambio,
      idUsuario,
      idMpSeVende,
      metodoPago,
      tipoCambio,
      cliente,
      estado,
    );
  }

  // Helper function for list comparison
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
