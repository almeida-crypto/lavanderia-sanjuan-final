import 'pedido_admin.dart';
import 'servicio_lavanderia.dart';

enum EstadoPedido { enProceso, atencion, entregado, cancelado }

EstadoPedido estadoPedidoFromString(String? value) {
  switch (value) {
    case 'Entregado':
      return EstadoPedido.entregado;
    case 'Cancelado':
      return EstadoPedido.cancelado;
    case 'Atención':
      return EstadoPedido.atencion;
    default:
      return EstadoPedido.enProceso;
  }
}

/// Representa un pedido tal como lo devuelve el backend, ya interpretado
/// para la UI (servicio real, estado real) en vez de asumir datos fijos.
class Pedido {
  const Pedido({
    required this.id,
    this.numeroOrden = 0,
    required this.servicio,
    required this.tipoServicio,
    required this.fecha,
    required this.franjaHoraria,
    required this.direccion,
    required this.instrucciones,
    required this.total,
    required this.estado,
    required this.estadoDetalle,
    this.fragancia,
    this.cantidadAproximada,
    this.metodoPago,
    this.totalConfirmado,
    this.repartidorNombre,
    this.repartidorTelefono,
    this.opcionAcabado,
    this.reporteTipo,
    this.reporteDetalles,
    this.reporteEstado,
    this.reporteRespuesta,
    this.recoleccionEnSucursal = false,
    this.entregaEnSucursal = false,
    this.evidenciaEntregaUrl,
    this.creadoEn,
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
      numeroOrden: int.tryParse(json['numeroOrden']?.toString() ?? '') ?? 0,
      servicio: servicioNombre,
      tipoServicio: tipoServicio,
      fecha: json['fecha']?.toString() ?? 'Sin fecha',
      franjaHoraria: json['franjaHoraria']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? 'Sin dirección',
      instrucciones: (instrucciones == null || instrucciones.isEmpty) ? null : instrucciones,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      estado: estadoPedidoFromString(json['estado']?.toString()),
      estadoDetalle: json['estado']?.toString() ?? 'Recibido',
      fragancia: json['fragancia']?.toString(),
      cantidadAproximada: int.tryParse(json['cantidadAproximada']?.toString() ?? ''),
      metodoPago: json['metodoPago']?.toString(),
      totalConfirmado: double.tryParse(json['totalConfirmado']?.toString() ?? ''),
      repartidorNombre: _cleanRepartidor(json['repartidor']?.toString()),
      repartidorTelefono: _cleanRepartidor(json['repartidorTelefono']?.toString()),
      opcionAcabado: json['opcionAcabado']?.toString(),
      creadoEn: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      reporteTipo: json['reporteTipo']?.toString(),
      reporteDetalles: json['reporteDetalles']?.toString(),
      reporteEstado: json['reporteEstado']?.toString(),
      reporteRespuesta: json['reporteRespuesta']?.toString(),
      recoleccionEnSucursal: json['recoleccionEnSucursal'] == true,
      entregaEnSucursal: json['entregaEnSucursal'] == true,
      evidenciaEntregaUrl: json['evidenciaEntregaUrl']?.toString(),
    );
  }

  static String? _cleanRepartidor(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  final String id;
  final int numeroOrden;
  final String servicio;
  final TipoServicio tipoServicio;
  final String fecha;
  final String franjaHoraria;
  final String direccion;
  final String? instrucciones;
  final double total;
  final EstadoPedido estado;

  /// Estado exacto que manda el backend. No se reduce a "en proceso" porque
  /// las reglas de cancelación dependen de la etapa real del pedido.
  final String estadoDetalle;

  /// La etapa operativa exacta que comparte con el panel administrador.
  /// [estado] se conserva para las reglas generales de la interfaz, mientras
  /// que este valor permite mostrar las diez opciones reales del flujo.
  PedidoEstado get estadoOperativo => pedidoEstadoFromString(estadoDetalle);

  final String? fragancia;
  final int? cantidadAproximada;
  final String? metodoPago;
  final double? totalConfirmado;
  final String? repartidorNombre;
  final String? repartidorTelefono;
  final String? opcionAcabado;
  final DateTime? creadoEn;
  final String? reporteTipo;
  final String? reporteDetalles;
  final String? reporteEstado;
  final String? reporteRespuesta;
  final bool recoleccionEnSucursal;
  final bool entregaEnSucursal;
  final String? evidenciaEntregaUrl;

  List<PedidoEstado> get flujoOperativo => estadosParaModalidad(
    recoleccionEnSucursal: recoleccionEnSucursal,
    entregaEnSucursal: entregaEnSucursal,
  );

  String get estadoOperativoTexto => estadoToStringParaModalidad(
    estadoOperativo,
    recoleccionEnSucursal: recoleccionEnSucursal,
    entregaEnSucursal: entregaEnSucursal,
  );

  double get progresoOperativo => progresoParaFlujo(
    estadoOperativo,
    flujoOperativo,
  );

  bool get tieneReporte => reporteTipo != null && reporteTipo!.trim().isNotEmpty;
  bool get tieneReporteAbierto =>
      tieneReporte && reporteEstado?.trim().toLowerCase() != 'resuelto';

  /// Folio corto y legible en vez del uuid interno (que es horrible de
  /// mostrar). Si por alguna razón el backend no lo mandó todavía (base sin
  /// migrar), cae a los primeros caracteres del id en vez del uuid completo.
  String get numero =>
      numeroOrden > 0 ? '#FC-${numeroOrden.toString().padLeft(5, '0')}' : '#FC-${id.substring(0, id.length < 8 ? id.length : 8)}';

  /// El total mostrado en la app hasta que el admin confirma peso/precio
  /// real; después de eso, este es el monto final a cobrar.
  double get precioFinal => totalConfirmado ?? total;

  bool get precioConfirmado => totalConfirmado != null;

  /// El cliente puede cancelar mientras el pedido todavía no ha entrado a
  /// planta. Después de eso el botón desaparece y el backend también lo
  /// rechaza, aunque alguien intente llamar la API directamente.
  bool get puedeCancelar => const {
    'Recibido',
    'Pedido recibido',
    'Asignado',
    'Repartidor Asignado',
    'Recolector asignado',
  }.contains(estadoDetalle);

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
