import 'usuario.dart';

class Empleado {
  Empleado({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.fechaRegistro,
    this.rol = UserRole.empleado,
    this.activo = true,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      correo: json['correo']?.toString() ?? json['email']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      fechaRegistro: json['fechaRegistro']?.toString() ?? '2026-01-01',
      rol: userRoleFromString(json['rol']?.toString() ?? json['role']?.toString()),
      activo: json['activo'] as bool? ?? true,
    );
  }

  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String fechaRegistro;
  final UserRole rol;
  final bool activo;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'telefono': telefono,
      'fechaRegistro': fechaRegistro,
      'rol': rol.name,
      'activo': activo,
    };
  }
}
