import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/servicio.dart';
import '../utils/api_config.dart';

class ServicioService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<List<Servicio>> listar() async {
    final response = await http.get(Uri.parse('$_baseUrl/servicios'));
    if (response.statusCode != 200) throw Exception('No se pudieron cargar los servicios');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Servicio.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Servicio> crear(Servicio servicio) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/servicios'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(servicio.toJson()),
    );
    if (response.statusCode != 201) throw Exception('No se pudo crear el servicio');
    return Servicio.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Servicio> actualizar(Servicio servicio) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/servicios/${servicio.id}'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(servicio.toJson()),
    );
    if (response.statusCode != 200) throw Exception('No se pudo actualizar el servicio');
    return Servicio.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
