class CategoriaMp {
  final int? id;
  final String nombre;
  final String unidad;
  final int fc;

  CategoriaMp({
    this.id,
    required this.nombre,
    required this.unidad,
    required this.fc,
  });
  factory CategoriaMp.fromJson(Map<String, dynamic> json) {
    return CategoriaMp(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      nombre: json['nombre'] as String,
      unidad: json['unidad'] as String,
      fc: (json['fc'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'unidad': unidad,
      'fc': fc,
    };
  }

  CategoriaMp copyWith({
    int? id,
    String? nombre,
    String? unidad,
    int? fc,
  }) {
    return CategoriaMp(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      fc: fc ?? this.fc,
    );
  }

  // Métodos de validación
  String? validarNombre() {
    if (nombre.trim().isEmpty) {
      return 'El nombre de la categoría es requerido';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? validarUnidad() {
    if (unidad.trim().isEmpty) {
      return 'La unidad de medida es requerida';
    }
    return null;
  }

  String? validarFc() {
    if (fc < 0) {
      return 'El factor de conversión no puede ser negativo';
    }
    return null;
  }

  // Método para validar todos los campos
  List<String> validar() {
    List<String> errores = [];
    
    String? errorNombre = validarNombre();
    if (errorNombre != null) errores.add(errorNombre);
    
    String? errorUnidad = validarUnidad();
    if (errorUnidad != null) errores.add(errorUnidad);
    
    String? errorFc = validarFc();
    if (errorFc != null) errores.add(errorFc);
    
    return errores;
  }

  // Método para verificar si la categoría es válida
  bool get esValida => validar().isEmpty;

  @override
  String toString() {
    return 'CategoriaMp(id: $id, nombre: $nombre, unidad: $unidad, fc: $fc)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoriaMp &&
        other.id == id &&
        other.nombre == nombre &&
        other.unidad == unidad &&
        other.fc == fc;
  }

  @override
  int get hashCode {
    return Object.hash(id, nombre, unidad, fc);
  }
}
