import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _userKey = 'saved_logged_user';

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Usuario? _currentUser;
  Usuario? get currentUser => _currentUser;

  bool _inicializando = true;
  bool get inicializando => _inicializando;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> cargarUsuarioGuardado() async {
    _inicializando = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null && userStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(userStr);
        _currentUser = Usuario.fromJson(map);
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _inicializando = false;
      notifyListeners();
    }
  }

  Future<void> _guardarUsuarioLocal(Usuario user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _eliminarUsuarioLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (_) {}
  }

  Future<bool> login({required String correo, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(correo: correo, password: password);
      if (_currentUser != null) {
        await _guardarUsuarioLocal(_currentUser!);
      }
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo conectar con el servidor';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registrar({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.registrar(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        telefono: telefono,
        password: password,
      );
      if (_currentUser != null) {
        await _guardarUsuarioLocal(_currentUser!);
      }
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo conectar con el servidor';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarPerfil({
    required String nombre,
    required String correo,
    String? telefono,
  }) async {
    final actual = _currentUser;
    if (actual == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final actualizado = await _authService.actualizarPerfil(
        Usuario(id: actual.id, nombre: nombre, correo: correo, telefono: telefono, rol: actual.rol),
      );
      _currentUser = actualizado;
      if (_currentUser != null) {
        await _guardarUsuarioLocal(_currentUser!);
      }
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo conectar con el servidor';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _eliminarUsuarioLocal();
    notifyListeners();
  }
}
