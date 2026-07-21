import 'package:flutter/material.dart';

/// Imagen administrable con respaldo local. Así ninguna tarjeta queda vacía
/// si el admin no ha subido foto o si la red falla.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    this.url,
    required this.fallbackAsset,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final String fallbackAsset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return Image.asset(fallbackAsset, fit: fit);
    return Image.network(
      value,
      fit: fit,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Image.asset(fallbackAsset, fit: fit),
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(fallbackAsset, fit: fit),
    );
  }
}

String imagenPredeterminadaServicio(String nombre) {
  final normalizado = nombre.toLowerCase();
  if (normalizado.contains('tintorer')) return 'assets/images/servicio_tintoreria.png';
  if (normalizado.contains('planch')) return 'assets/images/servicio_planchado.png';
  return 'assets/images/servicio_lavanderia.png';
}
