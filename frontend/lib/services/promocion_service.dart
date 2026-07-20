import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/promocion.dart';
import '../utils/api_config.dart';

class PromocionException implements Exception {
  PromocionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PromocionService {
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

  /// Le pregunta al backend si [codigo] realmente sirve para este cliente y
  /// este pedido (vigencia, servicio, cantidad mínima de prendas y usos ya
  /// gastados por este cliente) en vez de decidirlo con lo que ya se
  /// descargó en [listar]. Lanza [PromocionException] con el motivo exacto
  /// si no aplica.
  Future<Promocion> validar({
    required String codigo,
    required String servicio,
    required int cantidad,
  }) async {
    final response = await withTimeout(http.post(
      Uri.parse('$_baseUrl/promociones/validar'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'codigo': codigo, 'servicio': servicio, 'cantidad': cantidad}),
    ));
    if (response.statusCode != 200) {
      throw PromocionException(_extraerMensaje(response, 'Ese código no es válido'));
    }
    return Promocion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<Promocion>> listar() async {
    final response = await withTimeout(http.get(Uri.parse('$_baseUrl/promociones')));
    if (response.statusCode != 200) throw Exception('No se pudieron cargar las promociones');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Promocion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Promocion> crear(Promocion promocion) async {
    final response = await withTimeout(http.post(
      Uri.parse('$_baseUrl/promociones'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(promocion.toJson()),
    ));
    if (response.statusCode != 201) throw Exception('No se pudo crear la promoción');
    return Promocion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Promocion> actualizar(Promocion promocion) async {
    final response = await withTimeout(http.put(
      Uri.parse('$_baseUrl/promociones/${promocion.id}'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(promocion.toJson()),
    ));
    if (response.statusCode != 200) throw Exception('No se pudo actualizar la promoción');
    return Promocion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
