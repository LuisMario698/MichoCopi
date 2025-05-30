class Proveedor {
  final int? id;
  final String nombre;
  final String direccion;
  final int telefono;
  final int idCategoriaP;
  final String? email;
  final String? horario;          // Campo adicional según esquema DB
  final String horaApertura;      // Formato "HH:mm"
  final String horaCierre;        // Formato "HH:mm"

  Proveedor({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.idCategoriaP,
    this.email,
    this.horario,
    required this.horaApertura,
    required this.horaCierre,
  });

  // Constructor para crear desde JSON (para Supabase)
  factory Proveedor.fromJson(Map<String, dynamic> json) {
    String procesarHora(dynamic hora) {
      if (hora == null) return '09:00';
      if (hora is String) {
        // Si ya viene en formato HH:mm, lo usamos directamente
        if (hora.length <= 5) return hora;
        // Si viene como timestamp, extraemos la hora
        return hora.split(' ')[1].substring(0, 5);
      }
      return '09:00';
    }

    return Proveedor(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String,
      telefono: (json['telefono'] as num).toInt(),
      idCategoriaP: (json['id_Categoria_p'] as num).toInt(),
      email: json['email'] as String?,
      horario: json['horario'] as String?,
      horaApertura: procesarHora(json['hora_apertura']),
      horaCierre: procesarHora(json['hora_cierre']),
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
      if (horario != null) 'horario': horario,
      'hora_apertura': '2000-01-01 $horaApertura:00',
      'hora_cierre': '2000-01-01 $horaCierre:00',
    };
  }

  // Método especial para insertar (sin ID)
  Map<String, dynamic> toJsonForInsert() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'id_Categoria_p': idCategoriaP,
      if (email != null) 'email': email,
      if (horario != null) 'horario': horario,
      'hora_apertura': '2000-01-01 $horaApertura:00',
      'hora_cierre': '2000-01-01 $horaCierre:00',
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
    String? horario,
    String? horaApertura,
    String? horaCierre,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      idCategoriaP: idCategoriaP ?? this.idCategoriaP,
      email: email ?? this.email,
      horario: horario ?? this.horario,
      horaApertura: horaApertura ?? this.horaApertura,
      horaCierre: horaCierre ?? this.horaCierre,
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

  // Método para verificar si el proveedor está activo según su horario
  bool estaActivo() {
    final ahora = DateTime.now();
    final horaActual = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    
    // Convertir strings de hora a minutos para comparación
    final minutosApertura = _convertirHoraAMinutos(horaApertura);
    final minutosCierre = _convertirHoraAMinutos(horaCierre);
    final minutosActual = _convertirHoraAMinutos(horaActual);

    return minutosActual >= minutosApertura && minutosActual <= minutosCierre;
  }

  // Método helper para convertir hora en formato "HH:mm" a minutos
  int _convertirHoraAMinutos(String hora) {
    final partes = hora.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

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
    return 'Proveedor(id: $id, nombre: $nombre, direccion: $direccion, telefono: $telefono, idCategoriaP: $idCategoriaP, email: $email, horario: $horario, horaApertura: $horaApertura, horaCierre: $horaCierre)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Proveedor &&
        other.id == id &&
        other.nombre == nombre &&
        other.direccion == direccion &&
        other.telefono == telefono &&
        other.idCategoriaP == idCategoriaP &&
        other.email == email &&
        other.horario == horario &&
        other.horaApertura == horaApertura &&
        other.horaCierre == horaCierre;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nombre,
      direccion,
      telefono,
      idCategoriaP,
      email,
      horario,
      horaApertura,
      horaCierre,
    );
  }
}
