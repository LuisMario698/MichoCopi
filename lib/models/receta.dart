class Receta {
  final int? id;
  final List<int> idsMps;
  final List<int>
  cantidades; // Se mantiene por compatibilidad pero no se requiere

  Receta({this.id, required this.idsMps, this.cantidades = const []});

  factory Receta.fromJson(Map<String, dynamic> json) {
    final List<dynamic> idsMpsList = json['ids_Mps'] as List;
    final List<int> idsMps = idsMpsList.map((e) => (e as num).toInt()).toList();
    
    // Generamos cantidades con valor 1 para cada materia prima
    // Esto es para mantener compatibilidad interna del código
    // pero no se almacena en la base de datos
    final List<int> cantidades = List<int>.filled(idsMps.length, 1);
    
    return Receta(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      idsMps: idsMps,
      cantidades: cantidades, // Siempre usamos cantidades = 1 en memoria
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ids_Mps': idsMps,
      // Eliminamos 'cantidades' ya que no existe en el esquema de la base de datos
      // Mantenemos la información internamente en el objeto pero no lo enviamos a DB
    };
  }

  // Método especial para insertar (sin ID) - Compatible con esquema original
  Map<String, dynamic> toJsonForInsert() {
    return {
      'ids_Mps': idsMps,
      // Eliminamos 'cantidades' ya que no existe en el esquema de la base de datos
    };
  }

  // Método copyWith para crear copias con modificaciones
  Receta copyWith({int? id, List<int>? idsMps, List<int>? cantidades}) {
    return Receta(
      id: id ?? this.id,
      idsMps: idsMps ?? List.from(this.idsMps),
      // Las cantidades no son requeridas pero se mantiene para compatibilidad
      cantidades:
          cantidades ??
          (this.cantidades.isEmpty ? [] : List.from(this.cantidades)),
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
    // Las cantidades no son requeridas para las recetas
    return null;
  }

  // Método para validar todos los campos
  List<String> validar() {
    List<String> errores = [];

    String? errorIdsMps = validarIdsMps();
    if (errorIdsMps != null) errores.add(errorIdsMps);

    // Ya no validamos cantidades porque no son requeridas

    return errores;
  }

  // Método para verificar si la receta es válida
  bool get esValida => validar().isEmpty;

  // Agregar materia prima a la receta
  Receta agregarMateriaPrima(int idMateriaPrima, {int cantidad = 1}) {
    if (idsMps.contains(idMateriaPrima)) {
      throw ArgumentError('La materia prima ya existe en la receta');
    }

    List<int> nuevosIds = List.from(idsMps)..add(idMateriaPrima);
    // Ya no utilizamos cantidades

    return copyWith(idsMps: nuevosIds);
  }

  // Remover materia prima de la receta
  Receta removerMateriaPrima(int idMateriaPrima) {
    int index = idsMps.indexOf(idMateriaPrima);
    if (index == -1) {
      throw ArgumentError('La materia prima no existe en la receta');
    }

    List<int> nuevosIds = List.from(idsMps)..removeAt(index);
    // Ya no utilizamos cantidades

    return copyWith(idsMps: nuevosIds);
  }

  // Actualizar cantidad de materia prima - Método mantenido para compatibilidad
  Receta actualizarCantidad(int idMateriaPrima, int nuevaCantidad) {
    // Las cantidades no son requeridas para las recetas,
    // pero mantenemos el método por compatibilidad
    return this;
  }

  // Obtener cantidad de una materia prima específica - Método mantenido para compatibilidad
  int? obtenerCantidad(int idMateriaPrima) {
    // Las cantidades no son requeridas para las recetas
    return 1; // Valor por defecto
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
    return Object.hash(id, Object.hashAll(idsMps), Object.hashAll(cantidades));
  }

  @override
  String toString() {
    return 'Receta{id: $id, ingredientes: ${idsMps.length}}';
  }
}
