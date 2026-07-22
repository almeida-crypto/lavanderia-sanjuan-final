import 'package:url_launcher/url_launcher.dart';

/// Abre la dirección dada en la app de mapas del dispositivo (Google Maps,
/// Waze, Apple Maps, lo que tenga instalado) para navegación real, en vez de
/// intentar dibujar un mapa propio dentro de la app.
Future<bool> abrirEnMaps(String? direccion) async {
  final limpio = direccion?.trim();
  if (limpio == null || limpio.isEmpty || limpio == 'No especificado') return false;
  final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': limpio});
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
