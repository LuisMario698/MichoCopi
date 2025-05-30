class CorteInventario {
  final int id;
  final String inicioCorte; // Formato HH:MM:SS
  final String? finCorte; // Formato HH:MM:SS
  final List<int>? idsMps;
  final String fechaCorte; // Formato YYYY-MM-DD
  final String estado;
  final List<int>? stockInicial;
  final List<int>? stockFinal;

  CorteInventario({
    required this.id,
    required this.inicioCorte,
    this.finCorte,
    this.idsMps,
    required this.fechaCorte,
    required this.estado,
    this.stockInicial,
    this.stockFinal,
  });

  factory CorteInventario.fromJson(Map<String, dynamic> json) {
    return CorteInventario(
      id: json['id'] as int,
      inicioCorte: json['inicio_corte'] as String,
      finCorte: json['fin_corte'] as String?,
      idsMps:
          (json['ids_mps'] as List<dynamic>?)?.map((e) => e as int).toList(),
      fechaCorte: json['fecha_corte'] as String,
      estado: json['estado'] as String,
      stockInicial:
          (json['stock_inicial'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList(),
      stockFinal:
          (json['stock_final'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inicio_corte': inicioCorte,
      'fin_corte': finCorte,
      'ids_mps': idsMps,
      'fecha_corte': fechaCorte,
      'estado': estado,
      'stock_inicial': stockInicial,
      'stock_final': stockFinal,
    };
  }
}
