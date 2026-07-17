import 'servicio_lavanderia.dart';

enum EstadoPedido { enProceso, entregado, cancelado }

EstadoPedido estadoPedidoFromString(String? value) {
  switch (value) {
    case 'Entregado':
      return EstadoPedido.entregado;
    case 'Cancelado':
      return EstadoPedido.cancelado;
    default:
      return EstadoPedido.enProceso;
  }
}

/// Representa un pedido tal como lo devuelve el backend, ya interpretado
/// para la UI (servicio real, estado real) en vez de asumir datos fijos.
class Pedido {
  const Pedido({
    required this.id,
    required this.servicio,
    required this.tipoServicio,
    required this.fecha,
    required this.franjaHoraria,
    required this.direccion,
    required this.instrucciones,
    required this.total,
    required this.estado,
    this.ecoFriendly = false,
    this.fragancia,
    this.cantidadAproximada,
    this.metodoPago,
    this.totalConfirmado,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final servicioNombre = json['servicio']?.toString() ?? 'Servicio';
    final tipoServicio = serviciosDisponibles
        .firstWhere(
          (s) => s.nombre == servicioNombre,
          orElse: () => serviciosDisponibles.first,
        )
        .tipo;
    final instrucciones = json['instrucciones']?.toString().trim();

    return Pedido(
      id: json['id']?.toString() ?? '',
      servicio: servicioNombre,
      tipoServicio: tipoServicio,
      fecha: json['fecha']?.toString() ?? 'Sin fecha',
      franjaHoraria: json['franjaHoraria']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? 'Sin dirección',
      instrucciones: (instrucciones == null || instrucciones.isEmpty) ? null : instrucciones,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      estado: estadoPedidoFromString(json['estado']?.toString()),
      ecoFriendly: json['ecoFriendly'] == true,
      fragancia: json['fragancia']?.toString(),
      cantidadAproximada: int.tryParse(json['cantidadAproximada']?.toString() ?? ''),
      metodoPago: json['metodoPago']?.toString(),
      totalConfirmado: double.tryParse(json['totalConfirmado']?.toString() ?? ''),
    );
  }

  final String id;
  final String servicio;
  final TipoServicio tipoServicio;
  final String fecha;
  final String franjaHoraria;
  final String direccion;
  final String? instrucciones;
  final double total;
  final EstadoPedido estado;
  final bool ecoFriendly;
  final String? fragancia;
  final int? cantidadAproximada;
  final String? metodoPago;
  final double? totalConfirmado;

  String get numero => '#FC-$id';

  /// El total mostrado en la app hasta que el admin confirma peso/precio
  /// real; después de eso, este es el monto final a cobrar.
  double get precioFinal => totalConfirmado ?? total;

  bool get precioConfirmado => totalConfirmado != null;

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// El backend guarda la fecha como texto (a veces ISO 8601, a veces ya
  /// legible). Si se puede interpretar como fecha, se muestra en un
  /// formato corto y consistente; si no, se muestra tal cual llegó.
  String get fechaFormateada {
    final parsed = DateTime.tryParse(fecha);
    if (parsed == null) return fecha;
    return '${parsed.day} ${_meses[parsed.month - 1]}. ${parsed.year}';
  }
}
