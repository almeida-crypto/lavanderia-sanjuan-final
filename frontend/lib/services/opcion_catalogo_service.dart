import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/opcion_catalogo.dart';
import '../utils/api_config.dart';

class OpcionCatalogoService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<List<OpcionCatalogo>> listar() async {
    final response = await http.get(Uri.parse('$_baseUrl/opciones'));
    if (response.statusCode != 200) throw Exception('No se pudieron cargar las opciones');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => OpcionCatalogo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OpcionCatalogo> crear(OpcionCatalogo opcion) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/opciones'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(opcion.toJson()),
    );
    if (response.statusCode != 201) throw Exception('No se pudo crear la opción');
    return OpcionCatalogo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<OpcionCatalogo> actualizar(OpcionCatalogo opcion) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/opciones/${opcion.id}'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(opcion.toJson()),
    );
    if (response.statusCode != 200) throw Exception('No se pudo actualizar la opción');
    return OpcionCatalogo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
