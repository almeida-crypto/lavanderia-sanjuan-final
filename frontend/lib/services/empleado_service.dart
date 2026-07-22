import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/usuario.dart';
import '../utils/api_config.dart';

class EmpleadoException implements Exception {
  EmpleadoException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EmpleadoService {
  String get _baseUrl => ApiConfig.baseUrl;

  String _extraerMensaje(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
    } catch (_) {}
    return fallback;
  }

  Future<List<Usuario>> listar() async {
    final response = await withTimeout(http.get(Uri.parse('$_baseUrl/empleados'), headers: ApiConfig.authHeaders));
    if (response.statusCode != 200) {
      throw EmpleadoException(_extraerMensaje(response, 'No se pudo cargar el personal'));
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Usuario> crear({
    required String nombre,
    required String correo,
    required String password,
    required UserRole rol,
    String? telefono,
  }) async {
    final response = await withTimeout(http.post(
      Uri.parse('$_baseUrl/empleados'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'rol': rol.name,
        'telefono': telefono,
      }),
    ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw EmpleadoException(_extraerMensaje(response, 'No se pudo crear la cuenta'));
    }
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<Usuario> cambiarRol(String id, UserRole rol, {required String actorId}) async {
    final response = await withTimeout(http.put(
      Uri.parse('$_baseUrl/empleados/$id/rol'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'rol': rol.name, 'actorId': actorId}),
    ));
    if (response.statusCode != 200) {
      throw EmpleadoException(_extraerMensaje(response, 'No se pudo cambiar el rol'));
    }
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<Usuario> cambiarEstado(String id, bool activa, {required String actorId}) async {
    final response = await withTimeout(http.put(
      Uri.parse('$_baseUrl/empleados/$id/estado'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'activa': activa, 'actorId': actorId}),
    ));
    if (response.statusCode != 200) {
      throw EmpleadoException(_extraerMensaje(response, 'No se pudo cambiar el estado de la cuenta'));
    }
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<Usuario> cambiarPassword(
    String id, {
    required String nuevaPassword,
    required String actorCorreo,
    required String actorPassword,
  }) async {
    final response = await withTimeout(http.put(
      Uri.parse('$_baseUrl/empleados/$id/password'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({
        'nuevaPassword': nuevaPassword,
        'actorCorreo': actorCorreo,
        'actorPassword': actorPassword,
      }),
    ));
    if (response.statusCode != 200) {
      throw EmpleadoException(_extraerMensaje(response, 'No se pudo cambiar la contraseña'));
    }
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminar(String id, {required String actorId}) async {
    final response = await withTimeout(http.delete(
      Uri.parse('$_baseUrl/empleados/$id?actorId=$actorId'),
      headers: ApiConfig.authHeaders,
    ));
    if (response.statusCode != 200) {
      throw EmpleadoException(_extraerMensaje(response, 'No se pudo eliminar la cuenta'));
    }
  }

  Future<Usuario> cambiarTelefono(String id, String telefono) async {
    final response = await withTimeout(http.put(
      Uri.parse('$_baseUrl/empleados/$id/telefono'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'telefono': telefono}),
    ));
    if (response.statusCode != 200) throw EmpleadoException(_extraerMensaje(response, 'No se pudo actualizar el teléfono'));
    return Usuario.fromJson(jsonDecode(response.body));
  }
}
