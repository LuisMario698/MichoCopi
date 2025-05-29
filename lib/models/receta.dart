class Receta {
  final int? id;
  final String nombre;
  final String descripcion;
  final List<int> idMateriasPrimas;
  final List<double> cantidades;

  Receta({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.idMateriasPrimas,
    required this.cantidades,
  });

  // Constructor para crear desde JSON (para Supabase)
  factory Receta.fromJson(Map<String, dynamic> json) {
    return Receta(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      idMateriasPrimas: (json['id_materias_primas'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      cantidades: (json['cantidades'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'id_materias_primas': idMateriasPrimas,
      'cantidades': cantidades,
    };
  }

  // Método copyWith para crear copias con modificaciones
  Receta copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    List<int>? idMateriasPrimas,
    List<double>? cantidades,
  }) {
    return Receta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      idMateriasPrimas: idMateriasPrimas ?? List.from(this.idMateriasPrimas),
      cantidades: cantidades ?? List.from(this.cantidades),
    );
  }

  // Validaciones
  String? validarNombre() {
    if (nombre.trim().isEmpty) {
      return 'El nombre de la receta es requerido';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (nombre.trim().length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
    }
    return null;
  }

  String? validarDescripcion() {
    if (descripcion.trim().isEmpty) {
      return 'La descripción es requerida';
    }
    if (descripcion.trim().length < 5) {
      return 'La descripción debe tener al menos 5 caracteres';
    }
    if (descripcion.trim().length > 500) {
      return 'La descripción no puede exceder 500 caracteres';
    }
    return null;
  }

  String? validarMateriasPrimas() {
    if (idMateriasPrimas.isEmpty) {
      return 'Debe agregar al menos una materia prima';
    }
    if (idMateriasPrimas.length > 20) {
      return 'No puede agregar más de 20 materias primas';
    }
    // Verificar que no haya IDs duplicados
    Set<int> idsUnicos = Set.from(idMateriasPrimas);
    if (idsUnicos.length != idMateriasPrimas.length) {
      return 'No puede agregar la misma materia prima más de una vez';
    }
    // Verificar que todos los IDs sean válidos
    for (int id in idMateriasPrimas) {
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
    if (cantidades.length != idMateriasPrimas.length) {
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
    
    String? errorNombre = validarNombre();
    if (errorNombre != null) errores.add(errorNombre);
    
    String? errorDescripcion = validarDescripcion();
    if (errorDescripcion != null) errores.add(errorDescripcion);
    
    String? errorMateriasPrimas = validarMateriasPrimas();
    if (errorMateriasPrimas != null) errores.add(errorMateriasPrimas);
    
    String? errorCantidades = validarCantidades();
    if (errorCantidades != null) errores.add(errorCantidades);
    
    return errores;
  }

  // Método para verificar si la receta es válida
  bool get esValida => validar().isEmpty;

  // Agregar materia prima a la receta
  Receta agregarMateriaPrima(int idMateriaPrima, double cantidad) {
    if (idMateriasPrimas.contains(idMateriaPrima)) {
      throw ArgumentError('La materia prima ya existe en la receta');
    }
    
    List<int> nuevosIds = List.from(idMateriasPrimas)..add(idMateriaPrima);
    List<double> nuevasCantidades = List.from(cantidades)..add(cantidad);
    
    return copyWith(
      idMateriasPrimas: nuevosIds,
      cantidades: nuevasCantidades,
    );
  }

  // Remover materia prima de la receta
  Receta removerMateriaPrima(int idMateriaPrima) {
    int index = idMateriasPrimas.indexOf(idMateriaPrima);
    if (index == -1) {
      throw ArgumentError('La materia prima no existe en la receta');
    }
    
    List<int> nuevosIds = List.from(idMateriasPrimas)..removeAt(index);
    List<double> nuevasCantidades = List.from(cantidades)..removeAt(index);
    
    return copyWith(
      idMateriasPrimas: nuevosIds,
      cantidades: nuevasCantidades,
    );
  }

  // Actualizar cantidad de materia prima
  Receta actualizarCantidad(int idMateriaPrima, double nuevaCantidad) {
    int index = idMateriasPrimas.indexOf(idMateriaPrima);
    if (index == -1) {
      throw ArgumentError('La materia prima no existe en la receta');
    }
    
    List<double> nuevasCantidades = List.from(cantidades);
    nuevasCantidades[index] = nuevaCantidad;
    
    return copyWith(cantidades: nuevasCantidades);
  }

  // Obtener cantidad de una materia prima específica
  double? obtenerCantidad(int idMateriaPrima) {
    int index = idMateriasPrimas.indexOf(idMateriaPrima);
    return index != -1 ? cantidades[index] : null;
  }

  // Número total de ingredientes
  int get numeroIngredientes => idMateriasPrimas.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Receta &&
        other.id == id &&
        other.nombre == nombre &&
        other.descripcion == descripcion &&
        _listEquals(other.idMateriasPrimas, idMateriasPrimas) &&
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
      nombre,
      descripcion,
      Object.hashAll(idMateriasPrimas),
      Object.hashAll(cantidades),
    );
  }

  @override
  String toString() {
    return 'Receta{id: $id, nombre: $nombre, descripcion: $descripcion, ingredientes: ${idMateriasPrimas.length}}';
  }
}