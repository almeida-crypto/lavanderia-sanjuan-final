import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/promocion.dart';
import '../utils/api_config.dart';

class PromocionService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<List<Promocion>> listar() async {
    final response = await http.get(Uri.parse('$_baseUrl/promociones'));
    if (response.statusCode != 200) throw Exception('No se pudieron cargar las promociones');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Promocion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Promocion> crear(Promocion promocion) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/promociones'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(promocion.toJson()),
    );
    if (response.statusCode != 201) throw Exception('No se pudo crear la promoción');
    return Promocion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Promocion> actualizar(Promocion promocion) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/promociones/${promocion.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(promocion.toJson()),
    );
    if (response.statusCode != 200) throw Exception('No se pudo actualizar la promoción');
    return Promocion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
