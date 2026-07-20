import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tarjeta.dart';
import '../utils/api_config.dart';

class MetodoPagoService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<List<TarjetaGuardada>> listarMetodosPago(String usuarioId) async {
    final uri = Uri.parse('$_baseUrl/metodos-pago').replace(
      queryParameters: {'usuarioId': usuarioId},
    );
    final response = await withTimeout(http.get(uri, headers: ApiConfig.authHeaders));
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los métodos de pago');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((item) => TarjetaGuardada.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<TarjetaGuardada> guardarMetodoPago(String usuarioId, TarjetaGuardada tarjeta) async {
    final payload = tarjeta.toJson()..['usuarioId'] = usuarioId;
    final response = await withTimeout(http.post(
      Uri.parse('$_baseUrl/metodos-pago'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(payload),
    ));

    if (response.statusCode != 201) {
      throw Exception('No se pudo guardar el método de pago');
    }

    return TarjetaGuardada.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> eliminarMetodoPago(String id) async {
    final response = await withTimeout(http.delete(Uri.parse('$_baseUrl/metodos-pago/$id'), headers: ApiConfig.authHeaders));
    if (response.statusCode != 200) {
      throw Exception('No se pudo eliminar el método de pago');
    }
  }

  Future<TarjetaGuardada> marcarPrincipal(String usuarioId, String id) async {
    final response = await withTimeout(http.put(
      Uri.parse('$_baseUrl/metodos-pago/$id/principal'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'usuarioId': usuarioId}),
    ));
    if (response.statusCode != 200) {
      throw Exception('No se pudo marcar la tarjeta como principal');
    }
    return TarjetaGuardada.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
