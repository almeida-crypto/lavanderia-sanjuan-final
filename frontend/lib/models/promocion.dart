class Promocion {
  Promocion({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.descripcion,
    required this.descuentoPorcentaje,
    this.servicioAplicable,
    required this.fechaInicio,
    this.fechaFin,
    this.activa = true,
  });

  final String id;
  String codigo;
  String titulo;
  String descripcion;
  double descuentoPorcentaje;
  String? servicioAplicable;
  DateTime fechaInicio;
  DateTime? fechaFin;
  bool activa;

  /// Vigente = activada por el admin y dentro de la ventana de fechas que él
  /// configuró. Es lo único que determina si el cliente puede usarla.
  bool get vigente {
    if (!activa) return false;
    final ahora = DateTime.now();
    if (ahora.isBefore(fechaInicio)) return false;
    if (fechaFin != null && ahora.isAfter(fechaFin!)) return false;
    return true;
  }

  /// null o vacío = aplica a todos los servicios.
  bool aplicaAServicio(String nombreServicio) =>
      servicioAplicable == null ||
      servicioAplicable!.isEmpty ||
      servicioAplicable!.toLowerCase() == nombreServicio.toLowerCase();

  factory Promocion.fromJson(Map<String, dynamic> json) => Promocion(
    id: json['id']?.toString() ?? '',
    codigo: json['codigo']?.toString() ?? '',
    titulo: json['titulo']?.toString() ?? '',
    descripcion: json['descripcion']?.toString() ?? '',
    descuentoPorcentaje: double.tryParse(json['descuentoPorcentaje']?.toString() ?? '0') ?? 0,
    servicioAplicable: json['servicioAplicable']?.toString(),
    fechaInicio: DateTime.tryParse(json['fechaInicio']?.toString() ?? '') ?? DateTime.now(),
    fechaFin: json['fechaFin'] == null ? null : DateTime.tryParse(json['fechaFin'].toString()),
    activa: json['activa'] != false,
  );

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'titulo': titulo,
    'descripcion': descripcion,
    'descuentoPorcentaje': descuentoPorcentaje,
    'servicioAplicable': servicioAplicable,
    'fechaInicio': fechaInicio.toIso8601String(),
    'fechaFin': fechaFin?.toIso8601String(),
    'activa': activa,
  };
}
