import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

/// Envuelve una tarjeta de notificación para deslizarla: hacia la derecha
/// archiva, hacia la izquierda elimina (de la vista, no del dato original).
class NotificacionSwipeTile extends StatelessWidget {
  const NotificacionSwipeTile({
    super.key,
    required this.notifKey,
    required this.child,
    required this.onSwipe,
  });

  final String notifKey;
  final Widget child;
  final void Function(DismissDirection direction) onSwipe;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notifKey),
      direction: DismissDirection.horizontal,
      background: _fondo(
        alineacion: Alignment.centerLeft,
        color: AppColors.primary,
        icono: Icons.archive_rounded,
        texto: 'Archivar',
      ),
      secondaryBackground: _fondo(
        alineacion: Alignment.centerRight,
        color: AppColors.error,
        icono: Icons.delete_rounded,
        texto: 'Eliminar',
      ),
      onDismissed: onSwipe,
      child: child,
    );
  }

  Widget _fondo({
    required Alignment alineacion,
    required Color color,
    required IconData icono,
    required String texto,
  }) {
    final alDerecha = alineacion == Alignment.centerRight;
    return Container(
      alignment: alineacion,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alDerecha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Icon(icono, color: Colors.white),
          const SizedBox(height: 2),
          Text(
            texto,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
