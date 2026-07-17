import 'package:flutter/material.dart';

/// Comportamiento de scroll para toda la app: sin el efecto de estiramiento
/// que trae Flutter por defecto y con un tope firme al llegar al final.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
