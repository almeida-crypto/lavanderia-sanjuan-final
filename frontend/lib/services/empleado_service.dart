import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/usuario.dart';
import '../utils/api_config.dart';

class EmpleadoService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<List<Usuario>> listar() async {
    final response = await http.get(Uri.parse('$_baseUrl/empleados'));
    if (response.statusCode != 200) throw Exception('No se pudieron cargar los empleados');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Usuario> crear({
    required String nombre,
    required String correo,
    required String password,
    required UserRole rol,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/empleados'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'rol': userRoleToString(rol),
      }),
    );
    if (response.statusCode != 201) {
      final mensaje = _mensajeError(response.body);
      throw Exception(mensaje ?? 'No se pudo crear la cuenta');
    }
    return Usuario.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Usuario> cambiarRol(String id, UserRole rol, {required String actorId}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/empleados/$id/rol'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rol': userRoleToString(rol), 'actorId': actorId}),
    );
    if (response.statusCode != 200) {
      throw Exception(_mensajeError(response.body) ?? 'No se pudo actualizar el rol');
    }
    return Usuario.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Usuario> cambiarEstado(String id, bool activa, {required String actorId}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/empleados/$id/estado'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'activa': activa, 'actorId': actorId}),
    );
    if (response.statusCode != 200) {
      throw Exception(_mensajeError(response.body) ?? 'No se pudo actualizar el estado de la cuenta');
    }
    return Usuario.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> eliminar(String id, {required String actorId}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/empleados/$id?actorId=${Uri.encodeQueryComponent(actorId)}'),
    );
    if (response.statusCode != 200) {
      throw Exception(_mensajeError(response.body) ?? 'No se pudo eliminar la cuenta');
    }
  }

  String? _mensajeError(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded['message']?.toString() : null;
    } catch (_) {
      return null;
    }
  }
}
