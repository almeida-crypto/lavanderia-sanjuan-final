enum UserRole { cliente, administrador, empleado, repartidor }

UserRole userRoleFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'administrador':
    case 'admin':
      return UserRole.administrador;
    case 'empleado':
    case 'employee':
    case 'staff':
      return UserRole.empleado;
    case 'repartidor':
    case 'driver':
    case 'delivery':
      return UserRole.repartidor;
    case 'cliente':
    default:
      return UserRole.cliente;
  }
}

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.telefono,
    this.activo = true,
    this.accessToken,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'].toString(),
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? json['email'] as String? ?? '',
      telefono: json['telefono'] as String? ?? json['phone'] as String?,
      rol: userRoleFromString(json['rol'] as String? ?? json['role'] as String?),
      activo: json['activa'] != false,
      accessToken: json['accessToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'telefono': telefono,
      'rol': rol.name,
      'activa': activo,
      'accessToken': accessToken,
    };
  }

  final String id;
  final String nombre;
  final String correo;
  final String? telefono;
  final UserRole rol;
  final bool activo;

  /// Token de Supabase de esta sesión. Se persiste junto con el resto del
  /// perfil (SharedPreferences) para que la sesión sobreviva a un reinicio de
  /// la app sin tener que iniciar sesión de nuevo.
  final String? accessToken;
}
