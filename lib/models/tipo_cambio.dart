class TipoCambio {
  final int id;
  final double cambio;

  TipoCambio({
    required this.id,
    required this.cambio,
  });

  // Constructor para crear desde JSON (para Supabase)
  factory TipoCambio.fromJson(Map<String, dynamic> json) {
    return TipoCambio(
      id: (json['id'] as num).toInt(),
      cambio: (json['cambio'] as num).toDouble(),
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cambio': cambio,
    };
  }

  // Método especial para actualizar (sin ID ya que se usa el ID 1)
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'cambio': cambio,
    };
  }

  // Método copyWith para crear copias con modificaciones
  TipoCambio copyWith({
    int? id,
    double? cambio,
  }) {
    return TipoCambio(
      id: id ?? this.id,
      cambio: cambio ?? this.cambio,
    );
  }

  @override
  String toString() {
    return 'TipoCambio(id: $id, cambio: $cambio)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TipoCambio && other.id == id && other.cambio == cambio;
  }

  @override
  int get hashCode => id.hashCode ^ cambio.hashCode;
}
