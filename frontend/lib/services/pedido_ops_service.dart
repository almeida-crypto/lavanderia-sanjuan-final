import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/api_config.dart';

class PedidoOpsService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, dynamic>> cancelarPedido(String pedidoId, {required String razon, String? comentarios}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pedidos/$pedidoId/cancelar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'razon': razon, 'comentarios': comentarios}),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cancelar el pedido');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> calificarPedido(String pedidoId, {required int calificacionGeneral, String? resena}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pedidos/$pedidoId/calificar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'calificacionGeneral': calificacionGeneral, 'resena': resena}),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo enviar la calificación');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reportarProblema(String pedidoId, {required String tipo, String? detalles}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pedidos/$pedidoId/reportar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tipo': tipo, 'detalles': detalles}),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo enviar el reporte');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
