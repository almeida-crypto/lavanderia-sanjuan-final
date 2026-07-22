/// El backend a veces guarda la fecha como texto ya legible (ej.
/// "20/07/2026") y otras como una marca de tiempo ISO completa (ej.
/// "2026-07-20T00:00:00.000", con hora en ceros que no significa nada real).
/// Esto la deja siempre en un formato corto y legible sin esa hora; si no se
/// puede interpretar como fecha, se deja el texto tal cual llegó.
String formatearFecha(String valor) {
  final fecha = DateTime.tryParse(valor);
  if (fecha == null) return valor;
  const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
}
