import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/app_colors.dart';
import '../home_cliente/detalle_oferta_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import 'notificaciones_screen.dart';

class NotificacionDetalleScreen extends StatelessWidget {
  const NotificacionDetalleScreen({super.key, required this.notificacion});

  final Notificacion notificacion;

  ({String texto, IconData icon, WidgetBuilder builder})? get _accion {
    switch (notificacion.tipo) {
      case TipoNotificacion.pedidoRecolectado:
        return (
          texto: 'Ver Mis Pedidos',
          icon: Icons.local_shipping_rounded,
          builder: (_) => const MisPedidosScreen(),
        );
      case TipoNotificacion.promocion:
        return (
          texto: 'Ver Oferta',
          icon: Icons.sell_rounded,
          builder: (_) => const DetalleOfertaScreen(),
        );
      case TipoNotificacion.pedidoEntregado:
        return (
          texto: 'Ver Mis Pedidos',
          icon: Icons.receipt_long_rounded,
          builder: (_) => const MisPedidosScreen(),
        );
      case TipoNotificacion.informativa:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accion = _accion;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Notificación',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: notificacion.iconBg, shape: BoxShape.circle),
                  child: Icon(notificacion.icon, color: notificacion.iconColor, size: 36),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Text(
                  notificacion.titulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      notificacion.tiempo,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16),
                  ],
                ),
                child: Text(
                  notificacion.descripcion,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              if (accion != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: accion.builder),
                    ),
                    icon: Icon(accion.icon, size: 20),
                    label: Text(
                      accion.texto,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
