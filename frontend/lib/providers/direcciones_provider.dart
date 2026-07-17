import 'package:flutter/material.dart';

import '../models/direccion.dart';
import '../services/direccion_service.dart';

/// Fuente única de las direcciones guardadas del cliente, compartida entre
/// Mis Direcciones, Seleccionar Dirección y el flujo de Agendar Recolección.
class DireccionesProvider extends ChangeNotifier {
  DireccionesProvider({DireccionService? direccionService})
    : _direccionService = direccionService ?? DireccionService();

  final DireccionService _direccionService;
  final List<Direccion> _direcciones = [];
  String? _usuarioId;
  bool _isLoading = false;
  String? _error;

  List<Direccion> get direcciones => List.unmodifiable(_direcciones);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Null si todavía no ha cargado ninguna dirección (primera carga en
  /// curso, falló la conexión, o el cliente aún no tiene direcciones
  /// guardadas). Las pantallas que la usan deben manejar ese caso en vez
  /// de asumir que siempre hay al menos una.
  Direccion? get predeterminada => _direcciones.isEmpty
      ? null
      : _direcciones.firstWhere(
          (direccion) => direccion.predeterminada,
          orElse: () => _direcciones.first,
        );

  Future<void> cargarParaUsuario(String usuarioId) async {
    _usuarioId = usuarioId;
    await cargar();
  }

  Future<void> cargar() async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final datos = await _direccionService.listarDirecciones(usuarioId);
      _direcciones
        ..clear()
        ..addAll(datos);
      notifyListeners();
    } catch (_) {
      _error = 'No se pudieron cargar las direcciones';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Direccion> agregar(Direccion direccion) async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) throw Exception('Inicia sesión nuevamente');
    final esLaPrimera = _direcciones.isEmpty;
    final enviada = esLaPrimera ? direccion.copyWith(predeterminada: true) : direccion;
    final guardada = await _direccionService.crearDireccion(usuarioId, enviada);
    if (guardada.predeterminada) {
      for (var i = 0; i < _direcciones.length; i++) {
        _direcciones[i] = _direcciones[i].copyWith(predeterminada: false);
      }
    }
    _direcciones.add(guardada);
    notifyListeners();
    return guardada;
  }

  Future<void> actualizar(int index, Direccion direccion) async {
    final id = _direcciones[index].id;
    if (id == null) {
      // Nunca se guardó en el backend (id desconocido): solo se puede
      // actualizar el estado local.
      _direcciones[index] = direccion;
      notifyListeners();
      return;
    }

    final usuarioId = _usuarioId;
    if (usuarioId == null) throw Exception('Inicia sesión nuevamente');
    final actualizada = await _direccionService.actualizarDireccion(usuarioId, id, direccion);
    if (actualizada.predeterminada) {
      for (var i = 0; i < _direcciones.length; i++) {
        _direcciones[i] = _direcciones[i].copyWith(predeterminada: false);
      }
    }
    _direcciones[index] = actualizada;
    notifyListeners();
  }

  Future<void> eliminar(int index) async {
    final eraPredeterminada = _direcciones[index].predeterminada;
    final id = _direcciones[index].id;
    if (id != null) {
      await _direccionService.eliminarDireccion(id);
    }

    _direcciones.removeAt(index);
    if (eraPredeterminada && _direcciones.isNotEmpty) {
      await actualizar(0, _direcciones[0].copyWith(predeterminada: true));
      return;
    }
    notifyListeners();
  }

  Future<void> marcarPredeterminada(int index) async {
    await actualizar(index, _direcciones[index].copyWith(predeterminada: true));
  }

  void limpiar() {
    _usuarioId = null;
    _direcciones.clear();
    _error = null;
    notifyListeners();
  }
}
