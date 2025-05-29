class Receta {
  final int? id;
  final List<int> idsMps;
  final List<int> cantidades;

  Receta({
    this.id,
    required this.idsMps,
    required this.cantidades,
  });

  factory Receta.fromJson(Map<String, dynamic> json) {
    return Receta(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      idsMps: (json['ids_Mps'] as List).map((e) => (e as num).toInt()).toList(),
      cantidades: (json['cantidades'] as List).map((e) => (e as num).toInt()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ids_Mps': idsMps,
      'cantidades': cantidades,
    };
  }

  // Método copyWith para crear copias con modificaciones
  Receta copyWith({
    int? id,
    List<int>? idsMps,
    List<int>? cantidades,
  }) {
    return Receta(
      id: id ?? this.id,
      idsMps: idsMps ?? List.from(this.idsMps),
      cantidades: cantidades ?? List.from(this.cantidades),
    );
  }

  // Validaciones
  String? validarIdsMps() {
    if (idsMps.isEmpty) {
      return 'Debe agregar al menos una materia prima';
    }
    if (idsMps.length > 20) {
      return 'No puede agregar más de 20 materias primas';
    }
    // Verificar que no haya IDs duplicados
    Set<int> idsUnicos = Set.from(idsMps);
    if (idsUnicos.length != idsMps.length) {
      return 'No puede agregar la misma materia prima más de una vez';
    }
    // Verificar que todos los IDs sean válidos
    for (int id in idsMps) {
      if (id <= 0) {
        return 'Todas las materias primas deben tener un ID válido';
      }
    }
    return null;
  }

  String? validarCantidades() {
    if (cantidades.isEmpty) {
      return 'Debe especificar cantidades para las materias primas';
    }
    if (cantidades.length != idsMps.length) {
      return 'El número de cantidades debe coincidir con el número de materias primas';
    }
    // Verificar que todas las cantidades sean válidas
    for (int i = 0; i < cantidades.length; i++) {
      if (cantidades[i] <= 0) {
        return 'Todas las cantidades deben ser mayores a 0';
      }
      if (cantidades[i] > 999999) {
        return 'Las cantidades no pueden exceder 999,999';
      }
    }
    return null;
  }

  // Método para validar todos los campos
  List<String> validar() {
    List<String> errores = [];
    
    String? errorIdsMps = validarIdsMps();
    if (errorIdsMps != null) errores.add(errorIdsMps);
    
    String? errorCantidades = validarCantidades();
    if (errorCantidades != null) errores.add(errorCantidades);
    
    return errores;
  }

  // Método para verificar si la receta es válida
  bool get esValida => validar().isEmpty;

  // Agregar materia prima a la receta
  Receta agregarMateriaPrima(int idMateriaPrima, int cantidad) {
    if (idsMps.contains(idMateriaPrima)) {
      throw ArgumentError('La materia prima ya existe en la receta');
    }
    
    List<int> nuevosIds = List.from(idsMps)..add(idMateriaPrima);
    List<int> nuevasCantidades = List.from(cantidades)..add(cantidad);
    
    return copyWith(
      idsMps: nuevosIds,
      cantidades: nuevasCantidades,
    );
  }

  // Remover materia prima de la receta
  Receta removerMateriaPrima(int idMateriaPrima) {
    int index = idsMps.indexOf(idMateriaPrima);
    if (index == -1) {
      throw ArgumentError('La materia prima no existe en la receta');
    }
    
    List<int> nuevosIds = List.from(idsMps)..removeAt(index);
    List<int> nuevasCantidades = List.from(cantidades)..removeAt(index);
    
    return copyWith(
      idsMps: nuevosIds,
      cantidades: nuevasCantidades,
    );
  }

  // Actualizar cantidad de materia prima
  Receta actualizarCantidad(int idMateriaPrima, int nuevaCantidad) {
    int index = idsMps.indexOf(idMateriaPrima);
    if (index == -1) {
      throw ArgumentError('La materia prima no existe en la receta');
    }
    
    List<int> nuevasCantidades = List.from(cantidades);
    nuevasCantidades[index] = nuevaCantidad;
    
    return copyWith(cantidades: nuevasCantidades);
  }

  // Obtener cantidad de una materia prima específica
  int? obtenerCantidad(int idMateriaPrima) {
    int index = idsMps.indexOf(idMateriaPrima);
    return index != -1 ? cantidades[index] : null;
  }

  // Número total de ingredientes
  int get numeroIngredientes => idsMps.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Receta &&
        other.id == id &&
        _listEquals(other.idsMps, idsMps) &&
        _listEquals(other.cantidades, cantidades);
  }

  // Función auxiliar para comparar listas
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      Object.hashAll(idsMps),
      Object.hashAll(cantidades),
    );
  }

  @override
  String toString() {
    return 'Receta{id: $id, ingredientes: ${idsMps.length}}';
  }
}