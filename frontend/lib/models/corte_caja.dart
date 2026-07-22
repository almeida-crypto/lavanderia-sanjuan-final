import '../models/pedido_admin.dart';

/// Resumen de caja para un día específico: cuánto entró, cuántos pedidos se
/// recibieron/entregaron/cancelaron y cómo se pagó cada uno. Se calcula a
/// partir de los pedidos ya cargados en el panel (por fecha de creación),
/// no requiere una consulta aparte al backend.
class CorteCaja {
  const CorteCaja({
    required this.fecha,
    required this.pedidos,
    required this.ingresosTotales,
    required this.pedidosRecibidos,
    required this.pedidosEntregados,
    required this.pedidosCancelados,
    required this.pedidosEnProceso,
    required this.porMetodoPago,
  });

  final DateTime fecha;
  final List<PedidoAdmin> pedidos;
  final double ingresosTotales;
  final int pedidosRecibidos;
  final int pedidosEntregados;
  final int pedidosCancelados;
  final int pedidosEnProceso;

  /// Ej. {"Efectivo contra entrega": 320.0, "Tarjeta": 150.0}. Solo cuenta
  /// pedidos no cancelados, igual que [ingresosTotales].
  final Map<String, double> porMetodoPago;

  int get totalPedidos => pedidos.length;

  factory CorteCaja.calcular(List<PedidoAdmin> todosPedidos, DateTime fecha) {
    final delDia = todosPedidos.where((p) {
      final creado = p.creadoEn;
      return creado != null &&
          creado.year == fecha.year &&
          creado.month == fecha.month &&
          creado.day == fecha.day;
    }).toList();

    final noCancelados = delDia.where((p) => p.estado != PedidoEstado.cancelado);
    final ingresos = noCancelados.fold<double>(0, (suma, p) => suma + p.precioFinal);

    final porMetodo = <String, double>{};
    for (final p in noCancelados) {
      final metodo = (p.metodoPago == null || p.metodoPago!.isEmpty) ? 'Sin especificar' : p.metodoPago!;
      porMetodo[metodo] = (porMetodo[metodo] ?? 0) + p.precioFinal;
    }

    return CorteCaja(
      fecha: fecha,
      pedidos: delDia,
      ingresosTotales: ingresos,
      pedidosRecibidos: delDia.length,
      pedidosEntregados: delDia.where((p) => p.estado == PedidoEstado.entregado).length,
      pedidosCancelados: delDia.where((p) => p.estado == PedidoEstado.cancelado).length,
      pedidosEnProceso: delDia
          .where((p) =>
              p.estado != PedidoEstado.entregado &&
              p.estado != PedidoEstado.cancelado)
          .length,
      porMetodoPago: porMetodo,
    );
  }
}
