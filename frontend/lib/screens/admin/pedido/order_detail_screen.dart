import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido_admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';
import 'actualizar_estado_screen.dart';
import 'seleccionar_repartidor_screen.dart';

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

    final isWarning = currentPedido.estado == PedidoEstado.atencion &&
        currentPedido.warningMessage != null;

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
        child: SingleChildScrollView(
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
                  children: [
                    _buildRowDetail(
                      'Eco-friendly',
                      currentPedido.ecoFriendly ? 'Activado' : 'Desactivado',
                    ),
                    const Divider(color: AppColors.surfaceVariant, height: 24),
                    _buildRowDetail('Fragancia', currentPedido.fragancia ?? 'No especificada'),
                    if (currentPedido.cantidadAproximada != null) ...[
                      const Divider(color: AppColors.surfaceVariant, height: 24),
                      _buildRowDetail(
                        'Cantidad aproximada',
                        '${currentPedido.cantidadAproximada}',
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning, color: AppColors.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Requiere Atención Especial',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentPedido.warningMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
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

              // Entrega y repartidor
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
                    _buildRowDetail(
                      'Repartidor',
                      currentPedido.repartidorNombre ?? 'No asignado',
                      trailing: currentPedido.tipoEntrega == 'Domicilio'
                          ? TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SeleccionarRepartidorScreen(pedido: currentPedido),
                                ),
                              ),
                              child: Text(
                                currentPedido.repartidorNombre != null ? 'Cambiar' : 'Asignar',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
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
                            Text(
                              'Pagado con ${currentPedido.metodoPago}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
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
                            const SnackBar(content: Text('Ticket copiado para compartir o imprimir')),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copiar Ticket'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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
                                  nota.fecha,
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
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ActualizarEstadoScreen(pedido: currentPedido),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Actualizar Estado'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
