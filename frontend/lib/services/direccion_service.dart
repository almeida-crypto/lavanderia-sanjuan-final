import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/direccion.dart';
import '../utils/api_config.dart';

class DireccionService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<List<Direccion>> listarDirecciones(String usuarioId) async {
    final uri = Uri.parse('$_baseUrl/direcciones').replace(
      queryParameters: {'usuarioId': usuarioId},
    );
    final response = await withTimeout(http.get(uri, headers: ApiConfig.authHeaders));
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las direcciones');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Direccion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Direccion> crearDireccion(String usuarioId, Direccion direccion) async {
    final payload = direccion.toJson()..['usuarioId'] = usuarioId;
    final response = await withTimeout(http.post(
      Uri.parse('$_baseUrl/direcciones'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(payload),
    ));

    if (response.statusCode != 201) {
      throw Exception('No se pudo guardar la dirección');
    }

    return Direccion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Direccion> actualizarDireccion(String usuarioId, String id, Direccion direccion) async {
    final payload = direccion.toJson()..['usuarioId'] = usuarioId;
    final response = await withTimeout(http.put(
      Uri.parse('$_baseUrl/direcciones/$id'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(payload),
    ));

    if (response.statusCode != 200) {
      throw Exception('No se pudo actualizar la dirección');
    }

    return Direccion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> eliminarDireccion(String id) async {
    final response = await withTimeout(http.delete(Uri.parse('$_baseUrl/direcciones/$id'), headers: ApiConfig.authHeaders));
    if (response.statusCode != 200) {
      throw Exception('No se pudo eliminar la dirección');
    }
  }
}
