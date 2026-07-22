import 'package:url_launcher/url_launcher.dart';

/// Abre un chat de WhatsApp con el número ya listo (con mensaje precargado
/// opcional). Se usa en vez de la llamada telefónica porque no depende de
/// plan/saldo y es el medio que de verdad usa la lavandería para coordinar
/// recolecciones y entregas. Devuelve false si el número no es válido o no
/// hay una app capaz de abrir el enlace.
Future<bool> abrirWhatsApp(String? telefono, {String? mensaje}) async {
  final limpio = telefono?.replaceAll(RegExp(r'[^0-9]'), '');
  if (limpio == null || limpio.length < 10) return false;

  // Los enlaces wa.me necesitan el número completo con código de país; los
  // teléfonos de esta app se capturan a 10 dígitos (México), así que se les
  // antepone el 52 salvo que ya vengan con código de país incluido.
  final numero = limpio.length == 10 ? '52$limpio' : limpio;

  final uri = Uri.https('wa.me', '/$numero', mensaje == null || mensaje.isEmpty ? null : {'text': mensaje});
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
