import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias del cliente que se recuerdan entre pantallas y entre
/// sesiones, para preseleccionar opciones al agendar un nuevo pedido en
/// vez de volver a preguntar cada vez.
///
/// Cada cliente tiene sus propias preferencias: se guardan en el
/// almacenamiento local del dispositivo bajo una clave por usuario
/// (ver [cargarParaUsuario]), así que dos cuentas distintas en el mismo
/// dispositivo no se pisan entre sí.
class PreferenciasProvider extends ChangeNotifier {
  String? _userId;

  String _fragancia = 'Lavanda';
  String get fragancia => _fragancia;

  String _claveFragancia(String userId) => 'preferencias_fragancia_$userId';

  /// Carga las preferencias guardadas del usuario que acaba de iniciar
  /// sesión. Debe llamarse justo después de un login o registro exitoso.
  Future<void> cargarParaUsuario(String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    _fragancia = prefs.getString(_claveFragancia(userId)) ?? 'Lavanda';
    notifyListeners();
  }

  /// Limpia el estado en memoria al cerrar sesión (no borra lo guardado en
  /// disco, para que la próxima vez que ese cliente inicie sesión sus
  /// preferencias sigan ahí).
  void limpiar() {
    _userId = null;
    _fragancia = 'Lavanda';
    notifyListeners();
  }

  Future<void> establecerFragancia(String valor) async {
    _fragancia = valor;
    notifyListeners();
    final userId = _userId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveFragancia(userId), valor);
  }
}
