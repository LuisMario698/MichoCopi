class Proveedor {
  final int? id;
  final String nombre;
  final String direccion;
  final int telefono;
  final int idCategoriaP;
  final String? email;

  Proveedor({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.idCategoriaP,
    this.email,
  });
  // Constructor para crear desde JSON (para Supabase)
  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String,
      telefono: json['telefono'] as int,
      idCategoriaP: json['id_Categoria_p'] as int,
      email: json['email'] as String?,
    );
  }
  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'id_Categoria_p': idCategoriaP,
      if (email != null) 'email': email,
    };
  }
  // Método copyWith para crear copias con modificaciones
  Proveedor copyWith({
    int? id,
    String? nombre,
    String? direccion,
    int? telefono,
    int? idCategoriaP,
    String? email,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      idCategoriaP: idCategoriaP ?? this.idCategoriaP,
      email: email ?? this.email,
    );
  }

  // Métodos de validación
  String? validarNombre() {
    if (nombre.trim().isEmpty) {
      return 'El nombre del proveedor es requerido';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (nombre.trim().length > 255) {
      return 'El nombre no puede exceder 255 caracteres';
    }
    return null;
  }

  String? validarDireccion() {
    if (direccion.trim().isEmpty) {
      return 'La dirección es requerida';
    }
    if (direccion.trim().length < 5) {
      return 'La dirección debe tener al menos 5 caracteres';
    }
    if (direccion.trim().length > 255) {
      return 'La dirección no puede exceder 255 caracteres';
    }
    return null;
  }

  String? validarTelefono() {
    if (telefono <= 0) {
      return 'El teléfono debe ser un número válido';
    }
    // Verificar que el número tenga una longitud razonable
    String telefonoStr = telefono.toString();
    if (telefonoStr.length < 7 || telefonoStr.length > 15) {
      return 'El teléfono debe tener entre 7 y 15 dígitos';
    }
    return null;
  }

  String? validarIdCategoriaP() {
    if (idCategoriaP <= 0) {
      return 'Debe seleccionar una categoría válida';
    }
    return null;
  }

  // Método para validar todos los campos
  List<String> validar() {
    List<String> errores = [];
    
    String? errorNombre = validarNombre();
    if (errorNombre != null) errores.add(errorNombre);
    
    String? errorDireccion = validarDireccion();
    if (errorDireccion != null) errores.add(errorDireccion);
    
    String? errorTelefono = validarTelefono();
    if (errorTelefono != null) errores.add(errorTelefono);
    
    String? errorCategoria = validarIdCategoriaP();
    if (errorCategoria != null) errores.add(errorCategoria);
    
    return errores;
  }

  // Método para verificar si el proveedor es válido
  bool get esValido => validar().isEmpty;

  // Getters útiles
  String get telefonoFormateado {
    String telefonoStr = telefono.toString();
    if (telefonoStr.length == 10) {
      // Formato: (123) 456-7890
      return '(${telefonoStr.substring(0, 3)}) ${telefonoStr.substring(3, 6)}-${telefonoStr.substring(6)}';
    }
    return telefonoStr;
  }

  @override
  String toString() {
    return 'Proveedor(id: $id, nombre: $nombre, direccion: $direccion, telefono: $telefono, idCategoriaP: $idCategoriaP)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Proveedor &&
        other.id == id &&
        other.nombre == nombre &&
        other.direccion == direccion &&
        other.telefono == telefono &&
        other.idCategoriaP == idCategoriaP;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nombre,
      direccion,
      telefono,
      idCategoriaP,
    );
  }
}