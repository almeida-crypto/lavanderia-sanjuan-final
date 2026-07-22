import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido_admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/ticket_pdf_generator.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatear_fecha.dart';
import 'actualizar_estado_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.pedido});

  final PedidoAdmin pedido;

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios en el proveedor para tener los datos actualizados
    final currentPedido = context.watch<AdminProvider>().pedidos.firstWhere(
          (p) => p.id == pedido.id,
          orElse: () => pedido,
        );

    final isWarning = currentPedido.tieneReporteAbierto &&
        currentPedido.warningMessage != null;

    final esFinal = currentPedido.estado == PedidoEstado.entregado ||
        currentPedido.estado == PedidoEstado.cancelado;

    if (currentPedido.estado == PedidoEstado.cancelado) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Pedido ${currentPedido.numero}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.errorContainer, width: 1.5),
                ),
                color: AppColors.surfaceContainerLowest,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.error,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'PEDIDO CANCELADO',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este pedido se encuentra cancelado permanentemente y no está disponible para su visualización ni modificación.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const Divider(color: AppColors.surfaceVariant, height: 40),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detalles del Pedido:',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildRowDetail('Cliente', currentPedido.clienteNombre),
                            const SizedBox(height: 12),
                            _buildRowDetail('Teléfono', currentPedido.clienteTelefono),
                            const SizedBox(height: 12),
                            _buildRowDetail('Dirección', currentPedido.clienteDireccion),
                            const SizedBox(height: 12),
                            _buildRowDetail('Fecha de solicitud', currentPedido.fecha),
                            const Divider(color: AppColors.surfaceVariant, height: 24),
                            // Mostrar la razón si está en las notas
                            () {
                              final notaCancelacion = currentPedido.notas.firstWhere(
                                (n) => n.texto.startsWith('Cliente canceló:'),
                                orElse: () => const NotaPedido(fecha: '', texto: ''),
                              );
                              if (notaCancelacion.texto.isNotEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Motivo de Cancelación:',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notaCancelacion.texto.replaceFirst('Cliente canceló: ', ''),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            }(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pedido ${currentPedido.numero}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<AdminProvider>().cargarPedidos(),
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client details header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryFixed,
                      child: Text(
                        currentPedido.clienteNombre.substring(0, 1),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPedido.clienteNombre,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_laundry_service_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  currentPedido.servicioNombre,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentPedido.clienteEmail,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentPedido.clienteTelefono,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentPedido.clienteDireccion,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fecha: ${currentPedido.fecha}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Preferencias del cliente para este pedido
              Text(
                'Preferencias del Cliente',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRowDetail('Fragancia', currentPedido.fragancia ?? 'No especificada'),
                    if (currentPedido.cantidadAproximada != null) ...[
                      const Divider(color: AppColors.surfaceVariant, height: 24),
                      _buildRowDetail(
                        'Cantidad aproximada',
                        '${currentPedido.cantidadAproximada}',
                      ),
                    ],
                    if (currentPedido.detallesAdicionales != null) ...[
                      const Divider(color: AppColors.surfaceVariant, height: 24),
                      Text(
                        'Instrucciones especiales',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentPedido.detallesAdicionales!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (isWarning) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning, color: AppColors.error, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reporte del cliente · ${currentPedido.reporteEstado ?? 'Abierto'}',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error),
                                ),
                                const SizedBox(height: 4),
                                Text(currentPedido.warningMessage!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (currentPedido.reporteEstado != 'En revisión')
                            OutlinedButton(
                              onPressed: () => context.read<AdminProvider>().actualizarReporte(
                                currentPedido.id,
                                estado: 'En revisión',
                              ),
                              child: const Text('Tomar reporte'),
                            ),
                          ElevatedButton(
                            onPressed: () => _mostrarRespuestaReporte(context, currentPedido),
                            child: const Text('Responder y resolver'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Service details (desglose por artículo)
              Text(
                'Detalle del Servicio',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  children: [
                    for (final item in currentPedido.items) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nombre,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                if (item.descripcion != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.descripcion!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '\$${item.precio.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (item != currentPedido.items.last)
                        const Divider(color: AppColors.surfaceVariant, height: 20),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Entrega
              Text(
                'Entrega',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  children: [
                    _buildRowDetail('Tipo de entrega', currentPedido.tipoEntrega),
                    const Divider(color: AppColors.surfaceVariant, height: 24),
                    _buildRowDetail('Estado del envío', estadoToString(currentPedido.estado)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Resumen de pago
              Text(
                'Resumen de Pago',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  children: [
                    _buildPagoRow('Subtotal (${currentPedido.items.length} artículo(s))', currentPedido.subtotal),
                    _buildPagoRow('Impuestos (0%)', 0),
                    const Divider(color: AppColors.surfaceVariant, height: 24),
                    _buildPagoRow(
                      currentPedido.precioConfirmado ? 'Total Confirmado' : 'Total Estimado',
                      currentPedido.precioFinal,
                      destacado: true,
                    ),
                    if (!currentPedido.precioConfirmado) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Pendiente de confirmar el precio final tras pesar el pedido.',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _mostrarConfirmarPrecioDialog(context, currentPedido),
                          icon: const Icon(Icons.scale_outlined),
                          label: const Text('Confirmar Precio Final'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                    if (currentPedido.metodoPago != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Pagado con ${currentPedido.metodoPago}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(
                                text: 'Pedido ${currentPedido.numero}\n'
                                    'Cliente: ${currentPedido.clienteNombre}\n'
                                    'Servicio: ${currentPedido.servicioNombre}\n'
                                    'Total: \$${currentPedido.precioFinal.toStringAsFixed(2)}',
                              ));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ticket copiado para compartir')),
                              );
                            },
                            icon: const Icon(Icons.copy_outlined),
                            label: const Text('Copiar', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Printing.layoutPdf(
                                onLayout: (_) => generarTicketPdf(currentPedido),
                                name: 'Ticket ${currentPedido.numero}',
                              );
                            },
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Imprimir', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notas internas / línea de tiempo
              Text(
                'Notas Internas',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final nota in currentPedido.notas.reversed) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatearFecha(nota.fecha),
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                                ),
                                Text(
                                  nota.texto,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                if (nota.autor != null)
                                  Text(
                                    'Por ${nota.autor}',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (nota != currentPedido.notas.reversed.last)
                        const Padding(
                          padding: EdgeInsets.only(left: 3.5),
                          child: SizedBox(
                            height: 16,
                            child: VerticalDivider(color: AppColors.surfaceVariant, width: 1),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Estado actual
              Text(
                'Estado Actual',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconoParaEstado(currentPedido.estado),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        estadoToString(currentPedido.estado),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: esFinal
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ActualizarEstadoScreen(pedido: currentPedido),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esFinal ? AppColors.surfaceContainer : AppColors.primary,
                        foregroundColor: esFinal ? AppColors.onSurfaceVariant.withValues(alpha: 0.5) : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Actualizar', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarRespuestaReporte(BuildContext context, PedidoAdmin pedido) async {
    final controller = TextEditingController(text: pedido.reporteRespuesta);
    final respuesta = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Responder al cliente'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Respuesta o solución',
            hintText: 'Explica qué se revisó y cómo quedó resuelto.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Resolver'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (respuesta == null || !context.mounted) return;
    try {
      await context.read<AdminProvider>().actualizarReporte(
        pedido.id,
        estado: 'Resuelto',
        respuesta: respuesta,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respuesta enviada al cliente.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo resolver el reporte.')),
        );
      }
    }
  }

  Widget _buildRowDetail(String label, String value, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }

  void _mostrarConfirmarPrecioDialog(BuildContext context, PedidoAdmin currentPedido) {
    // Precio de referencia por kg/unidad: se deriva de la estimación original
    // (total ÷ cantidad aproximada) para poder sugerir el total en automático
    // en cuanto el admin capture el peso real. Si el pedido no trae cantidad
    // aproximada, no hay tarifa de referencia y el total se captura a mano.
    final cantidadEstimada = currentPedido.cantidadAproximada;
    final precioPorUnidad = (cantidadEstimada != null && cantidadEstimada > 0)
        ? currentPedido.total / cantidadEstimada
        : null;

    final pesoController = TextEditingController(text: cantidadEstimada?.toString() ?? '');
    final totalController = TextEditingController(text: currentPedido.total.toStringAsFixed(2));
    var isSaving = false;
    var totalEditadoManualmente = false;
    var isAutoUpdatingTotal = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void recalcularTotal(String pesoTexto) {
              if (precioPorUnidad == null || totalEditadoManualmente) return;
              final peso = double.tryParse(pesoTexto.trim());
              if (peso == null || peso <= 0) return;
              isAutoUpdatingTotal = true;
              totalController.text = (precioPorUnidad * peso).toStringAsFixed(2);
              isAutoUpdatingTotal = false;
            }

            Future<void> confirmar() async {
              final total = double.tryParse(totalController.text.trim());
              if (total == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa un total válido.')),
                );
                return;
              }

              setDialogState(() => isSaving = true);
              try {
                await context.read<AdminProvider>().confirmarPrecio(
                      currentPedido.id,
                      pesoConfirmado: double.tryParse(pesoController.text.trim()),
                      totalConfirmado: total,
                    );
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Precio final confirmado.')),
                );
              } catch (_) {
                setDialogState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo confirmar el precio, intenta de nuevo.')),
                );
              }
            }

            return AlertDialog(
              title: const Text('Confirmar Precio Final'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    precioPorUnidad != null
                        ? 'Ingresa el peso/cantidad real en kg (o la unidad del servicio). El total se calcula solo a partir de la tarifa de referencia: \$${precioPorUnidad.toStringAsFixed(2)}/kg. Puedes ajustarlo a mano si hace falta.'
                        : 'Ingresa el peso/cantidad real y el total a cobrar tras pesar el pedido.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pesoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso/cantidad real en kg (opcional)'),
                    onChanged: (value) => setDialogState(() => recalcularTotal(value)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Total a cobrar', prefixText: '\$ '),
                    onChanged: (_) {
                      if (!isAutoUpdatingTotal) totalEditadoManualmente = true;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : confirmar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPagoRow(String label, double valor, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: destacado ? 15 : 13,
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              color: destacado ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            '\$${valor.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: destacado ? 15 : 13,
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              color: destacado ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
