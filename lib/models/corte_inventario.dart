class CorteInventario {
  final int? id;
  final String inicioCorte; // "HH:mm:ss" format
  final String? finCorte; // "HH:mm:ss" format (nullable)
  final List<int>? idsMps; // Array de IDs de materias primas
  final DateTime fechaCorte; // Fecha del corte
  final String estado; // 'iniciado', 'en_proceso', 'finalizado'
  final List<int>? stockInicial; // Array de stock inicial
  final List<int>? stockFinal; // Array de stock final

  CorteInventario({
    this.id,
    required this.inicioCorte,
    this.finCorte,
    this.idsMps,
    required this.fechaCorte,
    this.estado = 'iniciado',
    this.stockInicial,
    this.stockFinal,
  });

  // Constructor para crear desde JSON (para Supabase)
  factory CorteInventario.fromJson(Map<String, dynamic> json) {
    // Función para convertir arrays PostgreSQL a List<int>
    List<int>? convertirArray(dynamic array) {
      if (array == null) return null;
      if (array is List) {
        return array.map((e) => (e as num).toInt()).toList();
      }
      if (array is String && array.startsWith('{') && array.endsWith('}')) {
        // Formato PostgreSQL: "{1,2,3}"
        String cleanArray = array.substring(1, array.length - 1);
        if (cleanArray.isEmpty) return [];
        return cleanArray.split(',').map((e) => int.parse(e.trim())).toList();
      }
      return null;
    }

    // Función para procesar tiempo
    String procesarTiempo(dynamic tiempo) {
      if (tiempo == null) return '00:00:00';
      if (tiempo is String) {
        // Si ya viene en formato HH:mm:ss, lo usamos
        if (tiempo.contains(':')) return tiempo;
        // Si viene como timestamp, extraemos solo la hora
        return tiempo.split(' ').last;
      }
      return '00:00:00';
    }

    return CorteInventario(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      inicioCorte: procesarTiempo(json['inicio_corte']),
      finCorte:
          json['fin_corte'] != null ? procesarTiempo(json['fin_corte']) : null,
      idsMps: convertirArray(json['ids_mps']),
      fechaCorte:
          json['fecha_corte'] != null
              ? DateTime.parse(json['fecha_corte'].toString())
              : DateTime.now(),
      estado: json['estado'] as String? ?? 'iniciado',
      stockInicial: convertirArray(json['stock_inicial']),
      stockFinal: convertirArray(json['stock_final']),
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    // Función para convertir List<int> a formato PostgreSQL
    String? formatearArray(List<int>? lista) {
      if (lista == null || lista.isEmpty) return null;
      return '{${lista.join(',')}}';
    }

    return {
      'id': id,
      'inicio_corte': inicioCorte,
      'fin_corte': finCorte,
      'ids_mps': formatearArray(idsMps),
      'fecha_corte':
          fechaCorte.toIso8601String().split('T')[0], // Solo fecha YYYY-MM-DD
      'estado': estado,
      'stock_inicial': formatearArray(stockInicial),
      'stock_final': formatearArray(stockFinal),
    };
  }

  // Método para inserción en BD (excluye campos auto-generados)
  Map<String, dynamic> toJsonForInsert() {
    String? formatearArray(List<int>? lista) {
      if (lista == null || lista.isEmpty) return null;
      return '{${lista.join(',')}}';
    }

    return {
      'inicio_corte': inicioCorte,
      'fin_corte': finCorte,
      'ids_mps': formatearArray(idsMps),
      'fecha_corte': fechaCorte.toIso8601String().split('T')[0],
      'estado': estado,
      'stock_inicial': formatearArray(stockInicial),
      'stock_final': formatearArray(stockFinal),
    };
  }

  // Crear copia con campos modificados
  CorteInventario copyWith({
    int? id,
    String? inicioCorte,
    String? finCorte,
    List<int>? idsMps,
    DateTime? fechaCorte,
    String? estado,
    List<int>? stockInicial,
    List<int>? stockFinal,
  }) {
    return CorteInventario(
      id: id ?? this.id,
      inicioCorte: inicioCorte ?? this.inicioCorte,
      finCorte: finCorte ?? this.finCorte,
      idsMps: idsMps ?? this.idsMps,
      fechaCorte: fechaCorte ?? this.fechaCorte,
      estado: estado ?? this.estado,
      stockInicial: stockInicial ?? this.stockInicial,
      stockFinal: stockFinal ?? this.stockFinal,
    );
  }

  // Método toString para debugging
  @override
  String toString() {
    return 'CorteInventario(id: $id, inicioCorte: $inicioCorte, finCorte: $finCorte, '
        'fechaCorte: $fechaCorte, estado: $estado, idsMps: ${idsMps?.length ?? 0} items, '
        'stockInicial: ${stockInicial?.length ?? 0} items, stockFinal: ${stockFinal?.length ?? 0} items)';
  }

  // Operadores de igualdad
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CorteInventario &&
        other.id == id &&
        other.inicioCorte == inicioCorte &&
        other.finCorte == finCorte &&
        other.fechaCorte == fechaCorte &&
        other.estado == estado;
  }

  @override
  int get hashCode {
    return Object.hash(id, inicioCorte, finCorte, fechaCorte, estado);
  }

  // Métodos utilitarios
  bool get estaIniciado => estado == 'iniciado';
  bool get estaEnProceso => estado == 'en_proceso';
  bool get estaFinalizado => estado == 'finalizado';

  bool get tieneStockInicial =>
      stockInicial != null && stockInicial!.isNotEmpty;
  bool get tieneStockFinal => stockFinal != null && stockFinal!.isNotEmpty;

  int get cantidadMateriasPrimas => idsMps?.length ?? 0;

  // Duración del corte (si está finalizado)
  Duration? get duracionCorte {
    if (finCorte == null) return null;
    try {
      final inicio = _parseTime(inicioCorte);
      final fin = _parseTime(finCorte!);
      return fin.difference(inicio);
    } catch (e) {
      return null;
    }
  }

  // Helper para parsear tiempo
  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]), // horas
      int.parse(parts[1]), // minutos
      parts.length > 2 ? int.parse(parts[2]) : 0, // segundos
    );
  }
}
