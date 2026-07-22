import 'package:url_launcher/url_launcher.dart';

/// Abre el marcador telefónico del celular con el número ya escrito.
/// Devuelve false cuando el dispositivo no tiene una aplicación capaz de
/// realizar llamadas o el número está vacío.
Future<bool> abrirLlamada(String? telefono) async {
  final limpio = telefono?.replaceAll(RegExp(r'[^0-9+]'), '');
  if (limpio == null || limpio.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: limpio);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
