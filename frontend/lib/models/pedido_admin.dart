import 'package:flutter/material.dart' show IconData, Icons;

enum PedidoEstado {
  recibido,
  asignado,
  enPlanta,
  lavando,
  secandoDoblado,
  listo,
  enCamino,
  entregado,
  atencion,
  cancelado,
}

const estadosOperativos = <PedidoEstado>[
  PedidoEstado.recibido,
  PedidoEstado.asignado,
  PedidoEstado.enPlanta,
  PedidoEstado.lavando,
  PedidoEstado.secandoDoblado,
  PedidoEstado.listo,
  PedidoEstado.enCamino,
  PedidoEstado.entregado,
];

/// Construye el recorrido real del pedido según quién transporta las prendas
/// en cada extremo. La etapa [PedidoEstado.listo] se conserva cuando el
/// cliente recoge en sucursal, pero en la interfaz se presenta como
/// "Listo para recoger" en vez de una asignación de repartidor.
List<PedidoEstado> estadosParaModalidad({
  required bool recoleccionEnSucursal,
  required bool entregaEnSucursal,
}) => <PedidoEstado>[
  PedidoEstado.recibido,
  if (!recoleccionEnSucursal) PedidoEstado.asignado,
  PedidoEstado.enPlanta,
  PedidoEstado.lavando,
  PedidoEstado.secandoDoblado,
  PedidoEstado.listo,
  if (!entregaEnSucursal) PedidoEstado.enCamino,
  PedidoEstado.entregado,
];

String estadoToStringParaModalidad(
  PedidoEstado estado, {
  required bool recoleccionEnSucursal,
  required bool entregaEnSucursal,
}) {
  if (estado == PedidoEstado.asignado && recoleccionEnSucursal) {
    return 'Pedido agendado';
  }
  if (estado == PedidoEstado.recibido && recoleccionEnSucursal) {
    return 'Pedido agendado';
  }
  if (estado == PedidoEstado.listo && entregaEnSucursal) {
    return 'Listo para recoger en sucursal';
  }
  if (estado == PedidoEstado.enCamino && entregaEnSucursal) {
    return 'Listo para recoger en sucursal';
  }
  return estadoToString(estado);
}

String subtituloParaEstadoParaModalidad(
  PedidoEstado estado, {
  required bool recoleccionEnSucursal,
  required bool entregaEnSucursal,
}) {
  if (estado == PedidoEstado.asignado && recoleccionEnSucursal) {
    return 'Lleva tus prendas a la sucursal en la fecha acordada.';
  }
  if (estado == PedidoEstado.recibido && recoleccionEnSucursal) {
    return 'Lleva tus prendas a la sucursal en la fecha acordada.';
  }
  if (estado == PedidoEstado.listo && entregaEnSucursal) {
    return 'Tus prendas están listas; puedes recogerlas en la sucursal.';
  }
  if (estado == PedidoEstado.enCamino && entregaEnSucursal) {
    return 'Tus prendas están listas; puedes recogerlas en la sucursal.';
  }
  return subtituloParaEstado(estado);
}

double progresoParaFlujo(PedidoEstado estado, List<PedidoEstado> flujo) {
  if (estado == PedidoEstado.entregado) return 1;
  if (estado == PedidoEstado.cancelado || estado == PedidoEstado.atencion) return 0;

  final indice = flujo.indexOf(estado);
  if (indice >= 0) return (indice + 1) / flujo.length;

  // Compatibilidad con pedidos antiguos que pudieran conservar una etapa
  // de transporte que hoy ya no corresponde a su modalidad.
  final indiceGeneral = estadosOperativos.indexOf(estado);
  if (indiceGeneral < 0) return 0;
  final completadas = flujo.where(
    (etapa) => estadosOperativos.indexOf(etapa) <= indiceGeneral,
  ).length;
  return completadas / flujo.length;
}

/// El backend guarda el estado como texto libre (el cliente solo distingue
/// enProceso/entregado/cancelado, pero el admin necesita las etapas
/// intermedias). Cualquier valor desconocido cae en "recibido".
PedidoEstado pedidoEstadoFromString(String? value) {
  // El backend usa ambos textos para la misma etapa según si la asignación
  // provino del botón rápido o del selector completo del administrador.
  final normalizado = value?.trim();
  if (normalizado == 'Recibido' || normalizado == 'Pedido recibido') {
    return PedidoEstado.recibido;
  }
  if (normalizado == 'Asignado' ||
      normalizado == 'Repartidor Asignado' ||
      normalizado == 'Recolector asignado') {
    return PedidoEstado.asignado;
  }
  if (normalizado == 'Listo' || normalizado == 'Repartidor asignado') {
    return PedidoEstado.listo;
  }

  return PedidoEstado.values.firstWhere(
    (e) => estadoToString(e) == value,
    orElse: () => PedidoEstado.recibido,
  );
}

String estadoToString(PedidoEstado estado) {
  switch (estado) {
    case PedidoEstado.recibido:
      return 'Pedido recibido';
    case PedidoEstado.asignado:
      return 'Recolector asignado';
    case PedidoEstado.enPlanta:
      return 'En Planta';
    case PedidoEstado.lavando:
      return 'Lavando';
    case PedidoEstado.secandoDoblado:
      return 'Secando y Doblado';
    case PedidoEstado.listo:
      return 'Repartidor asignado';
    case PedidoEstado.enCamino:
      return 'En camino';
    case PedidoEstado.entregado:
      return 'Entregado';
    case PedidoEstado.atencion:
      return 'Atención';
    case PedidoEstado.cancelado:
      return 'Cancelado';
  }
}

double progresoParaEstado(PedidoEstado estado) {
  if (estado == PedidoEstado.entregado) return 1;
  if (estado == PedidoEstado.cancelado || estado == PedidoEstado.atencion) return 0;
  final index = estadosOperativos.indexOf(estado);
  return index < 0 ? 0 : (index + 1) / estadosOperativos.length;
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
      return Icons.person_pin_circle_outlined;
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
      return 'Solicitud recibida; la lavandería preparará la recolección.';
    case PedidoEstado.asignado:
      return 'Recolector asignado para buscar las prendas.';
    case PedidoEstado.enPlanta:
      return 'Recibido en las instalaciones.';
    case PedidoEstado.lavando:
      return 'Proceso de lavado activo.';
    case PedidoEstado.secandoDoblado:
      return 'Prendas secándose y doblándose.';
    case PedidoEstado.enCamino:
      return 'El repartidor está en ruta de entrega.';
    case PedidoEstado.listo:
      return 'Repartidor asignado para entregar las prendas.';
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
    this.numeroOrden = 0,
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
    this.fragancia,
    this.cantidadAproximada,
    this.pesoConfirmado,
    this.totalConfirmado,
    this.metodoPago,
    this.warningMessage,
    this.reporteTipo,
    this.reporteDetalles,
    this.reporteEstado,
    this.reporteRespuesta,
    this.repartidorNombre,
    this.repartidorId,
    this.repartidorTelefono,
    this.detallesAdicionales,
    this.opcionAcabado,
    this.creadoEn,
    this.recoleccionEnSucursal = false,
    this.entregaEnSucursal = false,
    this.evidenciaEntregaUrl,
  });

  final String id;
  final int numeroOrden;
  /// Cuándo se creó el pedido (distinto de [fecha], que es la fecha de
  /// recolección que eligió el cliente). Null si el backend no lo mandó.
  final DateTime? creadoEn;
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
  String? fragancia;
  int? cantidadAproximada;
  double? pesoConfirmado;
  double? totalConfirmado;
  String? metodoPago;
  String? warningMessage;
  String? reporteTipo;
  String? reporteDetalles;
  String? reporteEstado;
  String? reporteRespuesta;
  String? repartidorNombre;
  String? repartidorId;
  String? repartidorTelefono;
  String? detallesAdicionales;
  String? opcionAcabado;

  /// El cliente lleva/recoge su ropa en la sucursal en vez de que un
  /// repartidor la recolecte/entregue a domicilio. Son independientes entre
  /// sí (ver [entregaEnSucursal]).
  final bool recoleccionEnSucursal;

  /// El cliente recoge su ropa en la sucursal en vez de que un repartidor
  /// se la lleve a domicilio.
  final bool entregaEnSucursal;

  /// Foto que subió el repartidor como evidencia al marcar el pedido como
  /// entregado. Null si aún no se ha entregado o el pedido es de antes de
  /// que existiera este requisito.
  String? evidenciaEntregaUrl;

  /// Folio corto y legible en vez del uuid interno.
  String get numero => numeroOrden > 0
      ? '#FC-${numeroOrden.toString().padLeft(5, '0')}'
      : '#FC-${id.substring(0, id.length < 8 ? id.length : 8)}';

  double get subtotal => items.fold(0, (suma, item) => suma + item.precio);
  double get total => subtotal;

  /// El total mostrado hasta que el admin confirma el peso/precio real;
  /// después de eso, este es el monto final a cobrar.
  double get precioFinal => totalConfirmado ?? total;

  bool get precioConfirmado => totalConfirmado != null;

  bool get tieneReporte => reporteTipo != null && reporteTipo!.trim().isNotEmpty;
  bool get tieneReporteAbierto =>
      tieneReporte && reporteEstado?.trim().toLowerCase() != 'resuelto';
}
