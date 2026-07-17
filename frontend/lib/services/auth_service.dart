import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/usuario.dart';
import '../utils/api_config.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  String get _baseUrl => ApiConfig.baseUrl;

  /// Llama al endpoint de login del backend.
  ///
  /// El backend es quien valida la contraseña y decide el rol del usuario
  /// (cliente/administrador). Este servicio solo debe:
  /// - Mandar correo y contraseña.
  /// - Si el backend responde 401 (contraseña incorrecta) o 404 (usuario no
  ///   existe), lanzar [AuthException] con un mensaje para mostrar en pantalla.
  /// - Si responde 200, construir un [Usuario] a partir del JSON, incluyendo
  ///   su `rol` ("cliente" u "administrador"), para que la app navegue a la
  ///   pantalla correcta.
  Future<Usuario> login({
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    );

    if (response.statusCode == 401 || response.statusCode == 404) {
      throw AuthException('Correo o contraseña incorrectos');
    }
    if (response.statusCode != 200) {
      throw AuthException('No se pudo iniciar sesión, intenta de nuevo');
    }

    return Usuario.fromJson(jsonDecode(response.body));
  }

  /// Llama al endpoint de registro del backend.
  ///
  /// El backend valida que el correo no esté ya registrado y crea el nuevo
  /// cliente. Este servicio solo debe:
  /// - Mandar los datos del formulario.
  /// - Si el backend responde 409 (correo ya registrado), lanzar
  ///   [AuthException] con un mensaje para mostrar en pantalla.
  /// - Si responde 200/201, construir un [Usuario] a partir del JSON.
  Future<Usuario> registrar({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'telefono': telefono,
        'password': password,
      }),
    );

    if (response.statusCode == 409) {
      throw AuthException('Ese correo ya está registrado');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException('No se pudo crear la cuenta, intenta de nuevo');
    }

    return Usuario.fromJson(jsonDecode(response.body));
  }

  /// Llama al endpoint que actualiza los datos del perfil del usuario.
  ///
  /// El backend valida el nuevo correo (que no choque con otra cuenta) y
  /// actualiza los datos. Este servicio solo debe mandar los campos y
  /// devolver el [Usuario] actualizado que responda el backend.
  Future<Usuario> actualizarPerfil(Usuario usuario) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/usuarios/${usuario.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': usuario.nombre,
        'correo': usuario.correo,
        'telefono': usuario.telefono,
      }),
    );

    if (response.statusCode != 200) {
      throw AuthException('No se pudo actualizar el perfil, intenta de nuevo');
    }

    return Usuario.fromJson(jsonDecode(response.body));
  }

  /// Llama al endpoint que cambia la contraseña del usuario autenticado.
  ///
  /// El backend valida que [passwordActual] sea correcta antes de guardar
  /// [passwordNueva]. Este servicio solo debe:
  /// - Mandar ambas contraseñas.
  /// - Si el backend responde 401 (contraseña actual incorrecta), lanzar
  ///   [AuthException] con un mensaje para mostrar en pantalla.
  Future<void> cambiarContrasena({
    required String correo,
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/usuarios/cambiar-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'passwordActual': passwordActual,
        'passwordNueva': passwordNueva,
      }),
    );

    if (response.statusCode == 401) {
      throw AuthException('La contraseña actual es incorrecta');
    }
    if (response.statusCode != 200) {
      throw AuthException('No se pudo actualizar la contraseña, intenta de nuevo');
    }
  }

  /// Llama al endpoint que envía el correo de recuperación de contraseña.
  ///
  /// El backend debe responder 200 aunque el correo no exista (para no
  /// revelar qué correos están registrados). Este servicio solo debe
  /// lanzar [AuthException] si la petición falla por completo.
  Future<void> solicitarRecuperacion({required String correo}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/recuperar-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo}),
    );

    if (response.statusCode != 200) {
      throw AuthException('No se pudo enviar el correo, intenta de nuevo');
    }
  }
}
