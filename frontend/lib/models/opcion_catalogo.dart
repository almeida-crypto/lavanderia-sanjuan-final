/// Una opción reutilizable (ej. "Doblado en Gancho") que el admin define UNA
/// vez y luego puede ofrecer en cualquier servicio, actual o nuevo, cada uno
/// con su propio precio adicional.
class OpcionCatalogo {
  OpcionCatalogo({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    this.activa = true,
  });

  final String id;
  String nombre;
  String descripcion;
  bool activa;

  factory OpcionCatalogo.fromJson(Map<String, dynamic> json) => OpcionCatalogo(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    descripcion: json['descripcion']?.toString() ?? '',
    activa: json['activa'] != false,
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'activa': activa,
  };

  OpcionCatalogo copyWith({String? nombre, String? descripcion, bool? activa}) => OpcionCatalogo(
    id: id,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    activa: activa ?? this.activa,
  );
}
