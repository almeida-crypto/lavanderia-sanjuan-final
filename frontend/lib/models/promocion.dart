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
    this.usosPorCliente,
    this.cantidadMinima,
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

  /// Cuántas veces puede usar el mismo cliente este código (null = sin
  /// límite). Se valida de verdad en el backend al aplicar el código y de
  /// nuevo al crear el pedido, no solo aquí.
  int? usosPorCliente;

  /// Cantidad mínima de prendas/kg para que el código aplique (null = sin
  /// mínimo), ej. "50% en más de 10 prendas".
  int? cantidadMinima;

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
    usosPorCliente: json['usosPorCliente'] == null ? null : int.tryParse(json['usosPorCliente'].toString()),
    cantidadMinima: json['cantidadMinima'] == null ? null : int.tryParse(json['cantidadMinima'].toString()),
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
    'usosPorCliente': usosPorCliente,
    'cantidadMinima': cantidadMinima,
  };

  /// Descripción legible de las condiciones extra que el admin haya
  /// configurado (cantidad mínima y/o usos por cliente), para mostrarla
  /// tanto en el detalle de la oferta como en la lista del admin.
  String? get condicionesTexto {
    final partes = <String>[];
    if (cantidadMinima != null) partes.add('Válido en pedidos de $cantidadMinima prenda(s) o más');
    if (usosPorCliente != null) {
      partes.add(usosPorCliente == 1 ? 'Un solo uso por cliente' : 'Hasta $usosPorCliente usos por cliente');
    }
    return partes.isEmpty ? null : partes.join(' · ');
  }
}
