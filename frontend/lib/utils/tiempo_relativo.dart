/// Texto relativo tipo "Hace 2 h" para mostrar cuándo pasó algo.
String tiempoRelativo(DateTime? momento) {
  if (momento == null) return '';
  final diff = DateTime.now().difference(momento);
  if (diff.inMinutes < 1) return 'Justo ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ayer';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
  return '${momento.day}/${momento.month}/${momento.year}';
}
