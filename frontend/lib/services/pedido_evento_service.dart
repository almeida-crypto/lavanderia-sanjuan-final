import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pedido_evento.dart';
import '../utils/api_config.dart';

class PedidoEventoService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<List<PedidoEvento>> listar({String? actorId}) async {
    final uri = Uri.parse('$_baseUrl/pedidos/eventos').replace(
      queryParameters: actorId == null ? null : {'actorId': actorId},
    );
    final response = await withTimeout(http.get(uri, headers: ApiConfig.authHeaders));
    if (response.statusCode != 200) {
      String mensaje = 'No se pudo cargar la actividad (código ${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] is String) {
          mensaje = '$mensaje: ${body['message']}';
        }
      } catch (_) {}
      throw Exception(mensaje);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .cast<Map<String, dynamic>>()
        .map(PedidoEvento.fromJson)
        .toList();
  }
}
