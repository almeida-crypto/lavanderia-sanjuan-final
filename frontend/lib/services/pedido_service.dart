import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/api_config.dart';

class PedidoService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<List<Map<String, dynamic>>> listarPedidos({String? clienteId}) async {
    final uri = Uri.parse('$_baseUrl/pedidos').replace(queryParameters: clienteId == null ? null : {'clienteId': clienteId});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los pedidos');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> crearPedido(Map<String, dynamic> pedido) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pedidos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pedido),
    );
    if (response.statusCode != 201) {
      throw Exception('No se pudo crear el pedido');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> actualizarEstado(String id, String estado) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/pedidos/$id/estado'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': estado}),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo actualizar el estado');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> asignarRepartidor(String id, String repartidor) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/pedidos/$id/repartidor'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'repartidor': repartidor}),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo asignar el repartidor');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmarPrecio(
    String id, {
    double? pesoConfirmado,
    required double totalConfirmado,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/pedidos/$id/confirmar-precio'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pesoConfirmado': pesoConfirmado, 'totalConfirmado': totalConfirmado}),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo confirmar el precio');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
