import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/pedido.dart';
import '../../../models/servicio_lavanderia.dart';
import '../../../utils/app_colors.dart';
import '../agendar_recoleccion/agendar_recoleccion_screen.dart';
import '../mi_perfil/metodos_pago_screen.dart';
import '../pedido/calificar_servicio_screen.dart';
import '../pedido/reportar_problema_screen.dart';
import '../../../widgets/app_image.dart';

class DetalleFacturaScreen extends StatelessWidget {
  const DetalleFacturaScreen({super.key, required this.pedido});

  final Pedido pedido;

  Future<void> _copiarResumen(BuildContext context) async {
    await Clipboard.setData(ClipboardData(
      text: 'Factura ${pedido.numero}\n'
          'Servicio: ${pedido.servicio}\n'
          'Fecha: ${pedido.fechaFormateada}\n'
          'Total: \$${pedido.total.toStringAsFixed(2)}\n'
          'Pago: ${pedido.metodoPago}',
    ));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resumen de factura copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicioInfo = serviciosDisponibles.firstWhere((s) => s.tipo == pedido.tipoServicio);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle de Factura',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              pedido.numero,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResumenCard(pedido: pedido),
              if ((pedido.evidenciaEntregaUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Evidencia de entrega',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      insetPadding: const EdgeInsets.all(16),
                      backgroundColor: Colors.black,
                      child: InteractiveViewer(
                        child: AppImage(url: pedido.evidenciaEntregaUrl, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: AppImage(url: pedido.evidenciaEntregaUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CalificarServicioScreen(
                      pedidoId: pedido.id,
                      numeroPedido: pedido.numero,
                    ),
                  ),
                ),
                icon: const Icon(Icons.star_outline_rounded, size: 20),
                label: Text(
                  'Calificar Servicio',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Servicios Solicitados',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ServiciosCard(
                icon: servicioInfo.icon,
                nombre: pedido.servicio,
                descripcion: servicioInfo.descripcion,
                instrucciones: pedido.instrucciones,
                monto: pedido.total,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Preferencias',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _PreferenciasCard(pedido: pedido),
              const SizedBox(height: 24),
              _TotalCard(pedido: pedido),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Método de Pago',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _MetodoPagoCard(
                metodoPago: pedido.metodoPago,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MetodosPagoScreen()),
                ),
              ),
              const SizedBox(height: 24),
              const _RepetirPromoCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomActionBar(
        onDescargar: () => _copiarResumen(context),
        onRepetir: () => Navigator.of(context).push(
          AgendarRecoleccionScreen.route(servicioInicial: pedido.tipoServicio),
        ),
        onReportar: pedido.estado == EstadoPedido.cancelado || pedido.tieneReporteAbierto
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReportarProblemaScreen(pedido: pedido)),
                ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeTextColor, badgeIcon, badgeTexto) = switch (pedido.estado) {
      EstadoPedido.entregado => (
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
        Icons.check_circle_rounded,
        'Entregado',
      ),
      EstadoPedido.cancelado => (
        AppColors.errorContainer,
        AppColors.onErrorContainer,
        Icons.cancel_rounded,
        'Cancelado',
      ),
      EstadoPedido.enProceso => (
        AppColors.primaryContainer,
        AppColors.primary,
        Icons.local_laundry_service_rounded,
        'En proceso',
      ),
      EstadoPedido.atencion => (
        AppColors.errorContainer,
        AppColors.onErrorContainer,
        Icons.warning_amber_rounded,
        'Atención requerida',
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pedido.fechaFormateada,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Fecha del pedido',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeTextColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      badgeTexto,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceVariant, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: AppColors.onSurfaceVariant, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido.numero,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                    ),
                    Text(
                      'Recolectado en: ${pedido.direccion}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiciosCard extends StatelessWidget {
  const _ServiciosCard({
    required this.icon,
    required this.nombre,
    required this.descripcion,
    required this.monto,
    this.instrucciones,
  });

  final IconData icon;
  final String nombre;
  final String descripcion;
  final double monto;
  final String? instrucciones;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurface),
                ),
                Text(
                  descripcion,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                if (instrucciones != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Instrucciones: $instrucciones',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '\$${monto.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenciasCard extends StatelessWidget {
  const _PreferenciasCard({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pedido.fragancia != null) ...[
            Row(
              children: [
                const Icon(Icons.spa_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Fragancia: ${pedido.fragancia}',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                ),
              ],
            ),
          ],
          if (pedido.cantidadAproximada != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.scale_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Cantidad aproximada: ${pedido.cantidadAproximada}',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                ),
              ],
            ),
          ],
          if (pedido.opcionAcabado != null && pedido.opcionAcabado!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.checkroom_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Acabado elegido: ${pedido.opcionAcabado}',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final confirmado = pedido.precioConfirmado;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                confirmado ? 'Total Confirmado' : 'Total Estimado',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text.rich(
                TextSpan(
                  text: '\$${pedido.precioFinal.toStringAsFixed(2)} ',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  children: [
                    TextSpan(
                      text: 'MXN',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!confirmado) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Este total es una referencia. Se confirmará cuando se pese o verifique tu pedido.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


class _MetodoPagoCard extends StatelessWidget {
  const _MetodoPagoCard({required this.onTap, this.metodoPago});

  final VoidCallback onTap;
  final String? metodoPago;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments_outlined, color: AppColors.onSecondaryContainer, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                metodoPago ?? 'No especificado',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _RepetirPromoCard extends StatelessWidget {
  const _RepetirPromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.replay_circle_filled_rounded,
              size: 96,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Necesitas lo mismo?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  'Repite este pedido con un solo toque y mantén tu ropa impecable.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.onDescargar, required this.onRepetir, this.onReportar});

  final VoidCallback onDescargar;
  final VoidCallback onRepetir;
  final VoidCallback? onReportar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDescargar,
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: Text(
                      'Copiar resumen',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRepetir,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      'Repetir Pedido',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            if (onReportar != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onReportar,
                  icon: const Icon(Icons.report_gmailerrorred_rounded, size: 18, color: AppColors.error),
                  label: Text(
                    'Reportar un Problema',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
