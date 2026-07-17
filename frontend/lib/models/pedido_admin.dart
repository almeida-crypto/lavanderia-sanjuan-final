import 'package:flutter/material.dart' show IconData, Icons;

enum PedidoEstado {
  recibido,
  asignado,
  enPlanta,
  lavando,
  secandoDoblado,
  enCamino,
  listo,
  entregado,
  atencion,
  cancelado,
}

/// El backend guarda el estado como texto libre (el cliente solo distingue
/// enProceso/entregado/cancelado, pero el admin necesita las etapas
/// intermedias). Cualquier valor desconocido cae en "recibido".
PedidoEstado pedidoEstadoFromString(String? value) {
  return PedidoEstado.values.firstWhere(
    (e) => estadoToString(e) == value,
    orElse: () => PedidoEstado.recibido,
  );
}

String estadoToString(PedidoEstado estado) {
  switch (estado) {
    case PedidoEstado.recibido:
      return 'Recibido';
    case PedidoEstado.asignado:
      return 'Repartidor Asignado';
    case PedidoEstado.enPlanta:
      return 'En Planta';
    case PedidoEstado.lavando:
      return 'Lavando';
    case PedidoEstado.secandoDoblado:
      return 'Secando y Doblado';
    case PedidoEstado.enCamino:
      return 'En camino';
    case PedidoEstado.listo:
      return 'Listo';
    case PedidoEstado.entregado:
      return 'Entregado';
    case PedidoEstado.atencion:
      return 'Atención';
    case PedidoEstado.cancelado:
      return 'Cancelado';
  }
}

IconData iconoParaEstado(PedidoEstado estado) {
  switch (estado) {
    case PedidoEstado.recibido:
      return Icons.shopping_basket_outlined;
    case PedidoEstado.asignado:
      return Icons.person_outline;
    case PedidoEstado.enPlanta:
      return Icons.storefront_outlined;
    case PedidoEstado.lavando:
      return Icons.local_laundry_service_rounded;
    case PedidoEstado.secandoDoblado:
      return Icons.iron_outlined;
    case PedidoEstado.enCamino:
      return Icons.local_shipping_outlined;
    case PedidoEstado.listo:
      return Icons.check_circle_outline_rounded;
    case PedidoEstado.entregado:
      return Icons.task_alt_rounded;
    case PedidoEstado.atencion:
      return Icons.warning_amber_rounded;
    case PedidoEstado.cancelado:
      return Icons.cancel_outlined;
  }
}

String subtituloParaEstado(PedidoEstado estado) {
  switch (estado) {
    case PedidoEstado.recibido:
      return 'Pedido recibido o recogido del cliente.';
    case PedidoEstado.asignado:
      return 'Repartidor asignado en camino a recolección.';
    case PedidoEstado.enPlanta:
      return 'Recibido en las instalaciones.';
    case PedidoEstado.lavando:
      return 'Proceso de lavado activo.';
    case PedidoEstado.secandoDoblado:
      return 'Prendas secándose y doblándose.';
    case PedidoEstado.enCamino:
      return 'El repartidor está en ruta de entrega.';
    case PedidoEstado.listo:
      return 'Listo para entrega o recogida.';
    case PedidoEstado.entregado:
      return 'Pedido completado y entregado.';
    case PedidoEstado.atencion:
      return 'Falta artículo o verificación manual requerida.';
    case PedidoEstado.cancelado:
      return 'El cliente canceló este pedido.';
  }
}

/// Un artículo o cargo dentro del servicio de un pedido (ej. "1x Edredón King
/// Size" o un extra como "Doblado especial"), para mostrar el desglose que
/// pide el diseño en vez de un solo nombre de servicio genérico.
class PedidoItem {
  const PedidoItem({required this.nombre, required this.precio, this.descripcion});

  final String nombre;
  final String? descripcion;
  final double precio;
}

/// Entrada de la línea de tiempo de actividad interna del pedido (cambios de
/// estado, notas del staff), como la sección "Notas Internas" del diseño.
class NotaPedido {
  const NotaPedido({required this.fecha, required this.texto, this.autor});

  final String fecha;
  final String texto;
  final String? autor;
}

/// Pedido visto desde el panel de administrador: incluye datos operativos
/// (repartidor, progreso, alertas) que el panel de cliente no necesita.
class PedidoAdmin {
  PedidoAdmin({
    required this.id,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.clienteTelefono,
    required this.clienteDireccion,
    required this.servicioNombre,
    required this.servicioIcono,
    required this.tipoEntrega,
    required this.estado,
    required this.progreso,
    required this.fecha,
    required this.items,
    required this.notas,
    this.ecoFriendly = false,
    this.fragancia,
    this.cantidadAproximada,
    this.pesoConfirmado,
    this.totalConfirmado,
    this.metodoPago,
    this.warningMessage,
    this.repartidorNombre,
    this.detallesAdicionales,
  });

  final String id;
  final String clienteNombre;
  final String clienteEmail;
  final String clienteTelefono;
  final String clienteDireccion;
  final String servicioNombre;
  final String servicioIcono;
  final String tipoEntrega;
  PedidoEstado estado;
  double progreso;
  final String fecha;
  List<PedidoItem> items;
  List<NotaPedido> notas;
  bool ecoFriendly;
  String? fragancia;
  int? cantidadAproximada;
  double? pesoConfirmado;
  double? totalConfirmado;
  String? metodoPago;
  String? warningMessage;
  String? repartidorNombre;
  String? detallesAdicionales;

  double get subtotal => items.fold(0, (suma, item) => suma + item.precio);
  double get total => subtotal;

  /// El total mostrado hasta que el admin confirma el peso/precio real;
  /// después de eso, este es el monto final a cobrar.
  double get precioFinal => totalConfirmado ?? total;

  bool get precioConfirmado => totalConfirmado != null;
}
