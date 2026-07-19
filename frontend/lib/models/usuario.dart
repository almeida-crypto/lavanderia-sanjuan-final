enum UserRole { cliente, empleado, administrador }

UserRole userRoleFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'administrador':
    case 'admin':
      return UserRole.administrador;
    case 'empleado':
    case 'trabajador':
      return UserRole.empleado;
    case 'cliente':
    default:
      return UserRole.cliente;
  }
}

String userRoleToString(UserRole rol) => switch (rol) {
  UserRole.administrador => 'administrador',
  UserRole.empleado => 'empleado',
  UserRole.cliente => 'cliente',
};

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.telefono,
    this.activo = true,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'].toString(),
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? json['email'] as String? ?? '',
      telefono: json['telefono'] as String? ?? json['phone'] as String?,
      rol: userRoleFromString(json['rol'] as String? ?? json['role'] as String?),
      activo: json['activa'] != false,
    );
  }

  final String id;
  final String nombre;
  final String correo;
  final String? telefono;
  final UserRole rol;
  final bool activo;
}
