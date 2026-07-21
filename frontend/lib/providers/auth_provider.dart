import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../utils/api_config.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _userKey = 'saved_logged_user';

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    WidgetsBinding.instance.addObserver(this);
  }

  final AuthService _authService;
  Timer? _renovacionTimer;
  bool _renovando = false;

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
        ApiConfig.authToken = _currentUser?.accessToken;
        await renovarSesion(silencioso: true);
        _programarRenovacion();
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
        ApiConfig.authToken = _currentUser!.accessToken;
        await _guardarUsuarioLocal(_currentUser!);
        _programarRenovacion();
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
    String? fotoUrl,
  }) async {
    final actual = _currentUser;
    if (actual == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final actualizado = await _authService.actualizarPerfil(
        Usuario(
          id: actual.id,
          nombre: nombre,
          correo: correo,
          telefono: telefono,
          rol: actual.rol,
          fotoUrl: fotoUrl ?? actual.fotoUrl,
        ),
      );
      // El endpoint de perfil no reenvía el access token (solo /auth/login lo
      // hace), así que hay que conservar el de la sesión actual o se perdería
      // la sesión autenticada en la siguiente petición.
      _currentUser = Usuario(
        id: actualizado.id,
        nombre: actualizado.nombre,
        correo: actualizado.correo,
        telefono: actualizado.telefono,
        rol: actualizado.rol,
        activo: actualizado.activo,
          accessToken: actual.accessToken,
          refreshToken: actual.refreshToken,
        fotoUrl: actualizado.fotoUrl ?? actual.fotoUrl,
      );
      await _guardarUsuarioLocal(_currentUser!);
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

  Future<void> logout([BuildContext? context]) async {
    _renovacionTimer?.cancel();
    _currentUser = null;
    _isLoading = false;
    _errorMessage = null;
    ApiConfig.authToken = null;
    await _eliminarUsuarioLocal();
    notifyListeners();
    if (context != null && context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _programarRenovacion() {
    _renovacionTimer?.cancel();
    if (_currentUser?.refreshToken == null) return;
    _renovacionTimer = Timer.periodic(
      const Duration(minutes: 40),
      (_) => renovarSesion(silencioso: true),
    );
  }

  Future<bool> renovarSesion({bool silencioso = false}) async {
    final actual = _currentUser;
    final token = actual?.refreshToken;
    if (actual == null || token == null || token.isEmpty || _renovando) return false;
    _renovando = true;
    try {
      final renovado = await _authService.renovarSesion(token);
      _currentUser = renovado;
      ApiConfig.authToken = renovado.accessToken;
      await _guardarUsuarioLocal(renovado);
      if (!silencioso) notifyListeners();
      return true;
    } catch (_) {
      // Un fallo temporal de red no elimina la sesión guardada. La próxima
      // reanudación o el temporizador vuelve a intentarlo automáticamente.
      return false;
    } finally {
      _renovando = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      renovarSesion(silencioso: true);
    }
  }

  @override
  void dispose() {
    _renovacionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
