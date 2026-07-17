class Servicio {
  Servicio({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.precio,
    required this.unidad,
    required this.descripcion,
    this.activo = true,
  });

  final String id;
  String nombre;
  String icono;
  double precio;
  String unidad;
  String descripcion;
  bool activo;

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? 'Servicio',
    icono: json['icono']?.toString() ?? 'local_laundry_service',
    precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
    unidad: json['unidad']?.toString() ?? 'kg',
    descripcion: json['descripcion']?.toString() ?? '',
    activo: json['activo'] != false,
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'icono': icono,
    'precio': precio,
    'unidad': unidad,
    'descripcion': descripcion,
    'activo': activo,
  };
}
