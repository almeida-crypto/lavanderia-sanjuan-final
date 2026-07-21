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

/// Avatar de red que nunca deja el ícono roto si la foto fue eliminada,
/// cambió de permiso o tarda en responder.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.radius,
    this.url,
  });

  final double radius;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      child: Icon(
        Icons.person_rounded,
        size: radius,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );

    if (value == null || value.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        value,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

String imagenPredeterminadaServicio(String nombre) {
  final normalizado = nombre.toLowerCase();
  if (normalizado.contains('tintorer')) return 'assets/images/servicio_tintoreria.png';
  if (normalizado.contains('planch')) return 'assets/images/servicio_planchado.png';
  return 'assets/images/servicio_lavanderia.png';
}
