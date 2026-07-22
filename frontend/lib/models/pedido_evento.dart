/// Un evento de la bitácora de actividad de un pedido (quién cambió el
/// estado, quién asignó repartidor, quién confirmó el precio).
class PedidoEvento {
  const PedidoEvento({
    required this.id,
    required this.pedidoId,
    this.pedidoNumero,
    this.clienteNombre,
    this.actorId,
    required this.actorNombre,
    this.actorRol,
    required this.accion,
    this.detalle,
    this.creadoEn,
  });

  final String id;
  final String pedidoId;
  final int? pedidoNumero;
  final String? clienteNombre;
  final String? actorId;
  final String actorNombre;
  final String? actorRol;
  final String accion;
  final String? detalle;
  final DateTime? creadoEn;

  factory PedidoEvento.fromJson(Map<String, dynamic> json) => PedidoEvento(
    id: json['id']?.toString() ?? '',
    pedidoId: json['pedidoId']?.toString() ?? '',
    pedidoNumero: int.tryParse(json['pedidoNumero']?.toString() ?? ''),
    clienteNombre: json['clienteNombre']?.toString(),
    actorId: json['actorId']?.toString(),
    actorNombre: json['actorNombre']?.toString() ?? 'Usuario',
    actorRol: json['actorRol']?.toString(),
    accion: json['accion']?.toString() ?? '',
    detalle: json['detalle']?.toString(),
    creadoEn: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );

  /// Folio corto y legible, igual que en el resto de la app.
  String get pedidoNumeroTexto =>
      pedidoNumero != null && pedidoNumero! > 0 ? '#FC-${pedidoNumero.toString().padLeft(5, '0')}' : '';
}

String etiquetaAccion(String accion) {
  switch (accion) {
    case 'estado_cambiado':
      return 'Cambió el estado';
    case 'pedido_recibido_en_planta':
      return 'Recibió el pedido en planta';
    case 'pedido_entregado':
      return 'Entregó el pedido';
    case 'repartidor_asignado':
      return 'Asignó repartidor';
    case 'precio_confirmado':
      return 'Confirmó el precio';
    default:
      return accion;
  }
}

String etiquetaRol(String? rol) {
  switch (rol) {
    case 'administrador':
      return 'Admin';
    case 'empleado':
      return 'Empleado';
    case 'repartidor':
      return 'Repartidor';
    default:
      return rol ?? '';
  }
}
