import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/app_colors.dart';
import 'notificacion_detalle_screen.dart';

enum TipoNotificacion { pedidoRecolectado, promocion, pedidoEntregado, informativa }

class Notificacion {
  const Notificacion({
    required this.tipo,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.titulo,
    required this.descripcion,
    required this.tiempo,
    this.leida = false,
  });

  final TipoNotificacion tipo;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String titulo;
  final String descripcion;
  final String tiempo;
  final bool leida;

  Notificacion copyWith({bool? leida}) => Notificacion(
    tipo: tipo,
    icon: icon,
    iconBg: iconBg,
    iconColor: iconColor,
    titulo: titulo,
    descripcion: descripcion,
    tiempo: tiempo,
    leida: leida ?? this.leida,
  );
}

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final List<Notificacion> _notificaciones = [
    Notificacion(
      tipo: TipoNotificacion.pedidoRecolectado,
      icon: Icons.local_shipping_rounded,
      iconBg: AppColors.primaryFixed,
      iconColor: AppColors.onPrimaryFixedVariant,
      titulo: 'Pedido #1234 recolectado',
      descripcion:
          'Tu ropa fue recolectada y va en camino a nuestras instalaciones. Te avisaremos cuando comience la limpieza.',
      tiempo: 'Justo ahora',
    ),
    Notificacion(
      tipo: TipoNotificacion.promocion,
      icon: Icons.sell_rounded,
      iconBg: AppColors.secondaryContainer,
      iconColor: AppColors.onSecondaryContainer,
      titulo: 'Promo: 20% de descuento en tintorería',
      descripcion:
          '¡Es temporada de limpieza! Usa el código FRESH20 al pagar para obtener 20% de descuento en todos los servicios de tintorería esta semana.',
      tiempo: 'Hace 2 horas',
      leida: true,
    ),
    Notificacion(
      tipo: TipoNotificacion.pedidoEntregado,
      icon: Icons.check_circle_rounded,
      iconBg: AppColors.surfaceContainerHigh,
      iconColor: AppColors.primary,
      titulo: 'Pedido #1233 entregado',
      descripcion:
          'Tu ropa recién lavada fue entregada en tu puerta. ¡Gracias por elegir FreshClean!',
      tiempo: 'Ayer',
      leida: true,
    ),
    Notificacion(
      tipo: TipoNotificacion.informativa,
      icon: Icons.info_rounded,
      iconBg: AppColors.surfaceContainer,
      iconColor: AppColors.onSurfaceVariant,
      titulo: 'Actualización de Zona de Servicio',
      descripcion:
          'Ampliamos nuestras zonas de entrega. Revisa la app para ver si tus amigos en el Distrito Norte ya están cubiertos.',
      tiempo: 'Lun, 10:00 AM',
      leida: true,
    ),
  ];

  void _abrirNotificacion(int index) {
    setState(() => _notificaciones[index] = _notificaciones[index].copyWith(leida: true));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificacionDetalleScreen(notificacion: _notificaciones[index]),
      ),
    );
  }

  void _borrarTodo() {
    setState(() => _notificaciones.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurfaceVariant),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Notificaciones',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (_notificaciones.isNotEmpty)
            TextButton(
              onPressed: _borrarTodo,
              child: Text(
                'Borrar Todo',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _notificaciones.isEmpty
            ? Center(
                child: Text(
                  'No tienes notificaciones',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    for (var i = 0; i < _notificaciones.length; i++) ...[
                      _NotificacionCard(
                        notificacion: _notificaciones[i],
                        onTap: () => _abrirNotificacion(i),
                      ),
                      if (i != _notificaciones.length - 1) const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _NotificacionCard extends StatelessWidget {
  const _NotificacionCard({required this.notificacion, required this.onTap});

  final Notificacion notificacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final noLeida = !notificacion.leida;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: noLeida
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.surfaceVariant,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (noLeida) Container(width: 4, color: AppColors.primary),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: notificacion.iconBg, shape: BoxShape.circle),
                  child: Icon(notificacion.icon, color: notificacion.iconColor, size: 22),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notificacion.titulo,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notificacion.tiempo,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: noLeida ? FontWeight.w600 : FontWeight.w400,
                              color: noLeida ? AppColors.primary : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notificacion.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
