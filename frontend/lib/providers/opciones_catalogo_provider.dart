import 'package:flutter/material.dart';

import '../models/opcion_catalogo.dart';
import '../services/opcion_catalogo_service.dart';

/// Catálogo global de opciones (ej. "Doblado en Gancho") que el admin
/// define una vez y que cualquier servicio puede referenciar. Fuente única
/// de verdad para resolver los nombres/descripciones que los servicios solo
/// guardan como referencia (ver OpcionAcabadoRef).
class OpcionesCatalogoProvider extends ChangeNotifier {
  final _service = OpcionCatalogoService();

  List<OpcionCatalogo> _opciones = [];
  bool _isLoading = false;

  List<OpcionCatalogo> get opciones => List.unmodifiable(_opciones);
  List<OpcionCatalogo> get activas => _opciones.where((o) => o.activa).toList();
  bool get isLoading => _isLoading;

  Future<void> cargar() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _opciones = await _service.listar();
    } catch (_) {
      // Se mantiene el catálogo previo (o vacío) si el backend no responde.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  OpcionCatalogo? porId(String id) {
    for (final opcion in _opciones) {
      if (opcion.id == id) return opcion;
    }
    return null;
  }
}
