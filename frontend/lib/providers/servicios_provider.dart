import 'package:flutter/material.dart';

import '../models/servicio.dart';
import '../models/servicio_lavanderia.dart';
import '../services/servicio_service.dart';

/// Catálogo real de servicios (precio, disponibilidad) tal como lo configura
/// el administrador en el panel. Antes la app del cliente usaba una lista
/// fija en código que nunca reflejaba lo que el admin editaba o desactivaba;
/// este provider es el punto único de verdad para precios/disponibilidad.
class ServiciosProvider extends ChangeNotifier {
  final _servicioService = ServicioService();

  List<Servicio> _servicios = [];
  bool _isLoading = false;

  List<Servicio> get servicios => List.unmodifiable(_servicios);
  List<Servicio> get activos => _servicios.where((s) => s.activo).toList();
  bool get isLoading => _isLoading;

  /// Siempre vuelve a pedir el catálogo al backend: es una lista chica (un
  /// puñado de servicios) y sale más barato refrescarla seguido que
  /// arriesgarse a que el cliente vea datos viejos después de que el admin
  /// edita algo (antes se guardaba en caché para toda la sesión de la app y
  /// los cambios del admin no se reflejaban sin reiniciarla).
  Future<void> cargar() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _servicios = await _servicioService.listar();
    } catch (_) {
      // Si el backend no responde, se mantiene el catálogo previo (o vacío)
      // y las pantallas caen de nuevo a los precios de referencia estáticos.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Identifica a qué pantalla/tipo interno corresponde un servicio real del
  /// backend, usando el mismo criterio por palabras clave que ya usa el
  /// panel de administrador para elegir el ícono.
  TipoServicio _tipoDe(Servicio servicio) {
    final n = servicio.nombre.toLowerCase();
    if (n.contains('planch')) return TipoServicio.planchado;
    if (n.contains('tintorer')) return TipoServicio.tintoreria;
    if (n.contains('edred')) return TipoServicio.edredones;
    return TipoServicio.lavadoYPlegado;
  }

  /// Busca el servicio real (precio/nombre actual del admin) que corresponde
  /// a un tipo de pantalla. Si el catálogo aún no cargó o no hay coincidencia,
  /// devuelve null y quien llama debe usar el valor de referencia estático.
  Servicio? paraTipo(TipoServicio tipo) {
    for (final servicio in _servicios) {
      if (_tipoDe(servicio) == tipo) return servicio;
    }
    return null;
  }
}
