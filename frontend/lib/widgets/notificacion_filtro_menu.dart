import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

enum VistaNotificaciones { activas, leidas, archivadas }

String tituloParaVista(VistaNotificaciones vista) {
  switch (vista) {
    case VistaNotificaciones.activas:
      return 'Notificaciones';
    case VistaNotificaciones.leidas:
      return 'Leídas';
    case VistaNotificaciones.archivadas:
      return 'Archivadas';
  }
}

/// Menú en el AppBar para alternar entre notificaciones recientes, ya
/// leídas y archivadas, sin ocupar una pantalla ni una pestaña aparte.
class NotificacionFiltroMenu extends StatelessWidget {
  const NotificacionFiltroMenu({super.key, required this.vista, required this.onChanged});

  final VistaNotificaciones vista;
  final ValueChanged<VistaNotificaciones> onChanged;

  IconData get _icono {
    switch (vista) {
      case VistaNotificaciones.activas:
        return Icons.filter_list_rounded;
      case VistaNotificaciones.leidas:
        return Icons.mark_email_read_outlined;
      case VistaNotificaciones.archivadas:
        return Icons.archive_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VistaNotificaciones>(
      tooltip: 'Filtrar notificaciones',
      icon: Icon(_icono, color: AppColors.primary),
      onSelected: onChanged,
      itemBuilder: (context) => [
        _item(VistaNotificaciones.activas, Icons.notifications_outlined, 'Recientes'),
        _item(VistaNotificaciones.leidas, Icons.mark_email_read_outlined, 'Leídas'),
        _item(VistaNotificaciones.archivadas, Icons.archive_outlined, 'Archivadas'),
      ],
    );
  }

  PopupMenuItem<VistaNotificaciones> _item(VistaNotificaciones valor, IconData icono, String texto) {
    final seleccionada = valor == vista;
    return PopupMenuItem(
      value: valor,
      child: Row(
        children: [
          Icon(icono, size: 18, color: seleccionada ? AppColors.primary : AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            texto,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w500,
              color: seleccionada ? AppColors.primary : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
