import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Envuelve una pantalla "raíz" (no hay nada más atrás en la navegación,
/// p. ej. porque se llegó aquí con pushReplacement) para que el botón de
/// retroceso del sistema no cierre la app de golpe sin avisar: la primera
/// vez muestra un aviso, y solo sale si se presiona de nuevo en los
/// siguientes 2 segundos.
class DobleBackParaSalir extends StatefulWidget {
  const DobleBackParaSalir({super.key, required this.child, this.antesDeSalir});

  final Widget child;

  /// Se llama antes de considerar salir. Si devuelve true, significa que ya
  /// se encargó del "back" (p. ej. volver a la primera pestaña) y no debe
  /// ni avisar ni salir de la app.
  final bool Function()? antesDeSalir;

  @override
  State<DobleBackParaSalir> createState() => _DobleBackParaSalirState();
}

class _DobleBackParaSalirState extends State<DobleBackParaSalir> {
  DateTime? _ultimoIntento;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.antesDeSalir?.call() == true) return;
        final ahora = DateTime.now();
        if (_ultimoIntento != null && ahora.difference(_ultimoIntento!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _ultimoIntento = ahora;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Presiona de nuevo para salir'), duration: Duration(seconds: 2)),
          );
      },
      child: widget.child,
    );
  }
}
