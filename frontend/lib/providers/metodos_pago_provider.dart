import 'package:flutter/material.dart';

import '../models/tarjeta.dart';
import '../services/metodo_pago_service.dart';

/// Fuente única de las tarjetas guardadas del cliente, compartida entre
/// Métodos de Pago y el flujo de Agendar Recolección.
class MetodosPagoProvider extends ChangeNotifier {
  MetodosPagoProvider({MetodoPagoService? metodoPagoService})
    : _metodoPagoService = metodoPagoService ?? MetodoPagoService();

  final MetodoPagoService _metodoPagoService;
  final List<TarjetaGuardada> _tarjetas = [];
  String? _usuarioId;
  bool _isLoading = false;
  String? _error;

  List<TarjetaGuardada> get tarjetas => List.unmodifiable(_tarjetas);
  bool get isLoading => _isLoading;
  String? get error => _error;

  TarjetaGuardada? get principal {
    for (final tarjeta in _tarjetas) {
      if (tarjeta.principal) return tarjeta;
    }
    return _tarjetas.isEmpty ? null : _tarjetas.first;
  }

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
      final datos = await _metodoPagoService.listarMetodosPago(usuarioId);
      _tarjetas
        ..clear()
        ..addAll(datos);
      notifyListeners();
    } catch (_) {
      _error = 'No se pudieron cargar los métodos de pago';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TarjetaGuardada> agregar(TarjetaGuardada tarjeta) async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) throw Exception('Inicia sesión nuevamente');
    final guardada = await _metodoPagoService.guardarMetodoPago(usuarioId, tarjeta);
    if (guardada.principal) {
      for (var i = 0; i < _tarjetas.length; i++) {
        _tarjetas[i] = _tarjetas[i].copyWith(principal: false);
      }
    }
    _tarjetas.add(guardada);
    notifyListeners();
    return guardada;
  }

  Future<void> eliminar(int index) async {
    final eraPrincipal = _tarjetas[index].principal;
    final id = _tarjetas[index].id;
    if (id == null) throw Exception('La tarjeta no tiene un identificador');
    await _metodoPagoService.eliminarMetodoPago(id);
    _tarjetas.removeAt(index);
    if (eraPrincipal && _tarjetas.isNotEmpty) {
      final nuevoId = _tarjetas[0].id;
      if (nuevoId != null && _usuarioId != null) {
        await _metodoPagoService.marcarPrincipal(_usuarioId!, nuevoId);
      }
      _tarjetas[0] = _tarjetas[0].copyWith(principal: true);
    }
    notifyListeners();
  }

  Future<void> marcarPrincipal(int index) async {
    final usuarioId = _usuarioId;
    final id = _tarjetas[index].id;
    if (usuarioId == null || id == null) throw Exception('Inicia sesión nuevamente');
    await _metodoPagoService.marcarPrincipal(usuarioId, id);
    for (var i = 0; i < _tarjetas.length; i++) {
      _tarjetas[i] = _tarjetas[i].copyWith(principal: i == index);
    }
    notifyListeners();
  }

  void limpiar() {
    _usuarioId = null;
    _tarjetas.clear();
    _error = null;
    notifyListeners();
  }
}
