import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class MensajeSoporte {
  const MensajeSoporte({required this.id, required this.autorId, required this.autorNombre, required this.mensaje, required this.createdAt});
  factory MensajeSoporte.fromJson(Map<String, dynamic> json) => MensajeSoporte(
    id: json['id']?.toString() ?? '',
    autorId: json['autorId']?.toString() ?? '',
    autorNombre: json['autorNombre']?.toString() ?? 'Usuario',
    mensaje: json['mensaje']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
  final String id;
  final String autorId;
  final String autorNombre;
  final String mensaje;
  final DateTime createdAt;
}

class ConversacionSoporte {
  const ConversacionSoporte({required this.clienteId, required this.clienteNombre, required this.ultimoMensaje, required this.noLeidos});
  factory ConversacionSoporte.fromJson(Map<String, dynamic> json) => ConversacionSoporte(
    clienteId: json['clienteId']?.toString() ?? '',
    clienteNombre: json['clienteNombre']?.toString() ?? 'Cliente',
    ultimoMensaje: json['ultimoMensaje']?.toString() ?? '',
    noLeidos: int.tryParse(json['noLeidos']?.toString() ?? '0') ?? 0,
  );
  final String clienteId;
  final String clienteNombre;
  final String ultimoMensaje;
  final int noLeidos;
}

class SoporteService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<List<MensajeSoporte>> mensajes({String? clienteId}) async {
    final uri = Uri.parse('$_baseUrl/soporte/mensajes').replace(
      queryParameters: clienteId == null ? null : {'clienteId': clienteId},
    );
    final response = await withTimeout(http.get(uri, headers: ApiConfig.authHeaders));
    if (response.statusCode != 200) throw Exception(_mensaje(response, 'No se pudo abrir el chat'));
    return (jsonDecode(response.body) as List).map((e) => MensajeSoporte.fromJson(e)).toList();
  }

  Future<List<ConversacionSoporte>> conversaciones() async {
    final response = await withTimeout(http.get(Uri.parse('$_baseUrl/soporte/conversaciones'), headers: ApiConfig.authHeaders));
    if (response.statusCode != 200) throw Exception(_mensaje(response, 'No se pudieron cargar las conversaciones'));
    return (jsonDecode(response.body) as List).map((e) => ConversacionSoporte.fromJson(e)).toList();
  }

  Future<void> enviar(String mensaje, {String? clienteId, String? clienteNombre}) async {
    final response = await withTimeout(http.post(
      Uri.parse('$_baseUrl/soporte/mensajes'),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'mensaje': mensaje, 'clienteId': clienteId, 'clienteNombre': clienteNombre}),
    ));
    if (response.statusCode != 200) throw Exception(_mensaje(response, 'No se pudo enviar el mensaje'));
  }

  Future<void> marcarLeidos({String? clienteId}) async {
    final uri = Uri.parse('$_baseUrl/soporte/leer').replace(
      queryParameters: clienteId == null ? null : {'clienteId': clienteId},
    );
    await withTimeout(http.put(uri, headers: ApiConfig.authHeaders));
  }

  String _mensaje(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) return body['message'];
    } catch (_) {}
    return fallback;
  }
}
