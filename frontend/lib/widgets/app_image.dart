import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Imagen administrable con respaldo en el logo de la marca. Así ninguna
/// tarjeta queda vacía o rota si el admin no ha subido foto, la borró, o la
/// red falla.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    this.url,
    this.fallbackAsset,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final String? fallbackAsset;
  final BoxFit fit;

  Widget _fallback() {
    final asset = fallbackAsset;
    if (asset != null) return Image.asset(asset, fit: fit);
    return const AppLogoMark();
  }

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return _fallback();
    return Image.network(
      value,
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null ? child : _fallback(),
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }
}

/// Marca de FreshClean (el mismo cuadro con el ícono de lavandería que se ve
/// en la pantalla de bienvenida y en las barras superiores), usada como
/// respaldo cuando un servicio o promoción no tiene imagen asignada.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryContainer,
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: 0.4,
        heightFactor: 0.4,
        child: FittedBox(
          child: Icon(Icons.local_laundry_service_rounded, color: AppColors.primary),
        ),
      ),
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
