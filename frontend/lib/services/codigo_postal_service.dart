import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/api_config.dart';

class CodigoPostalException implements Exception {
  CodigoPostalException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lo que el backend devuelve para un código postal real, consultado contra
/// el catálogo oficial de SEPOMEX (no un texto inventado): el estado y la
/// ciudad/municipio a los que pertenece, y todas las colonias reales que
/// existen en ese CP (casi siempre hay varias).
class InfoCodigoPostal {
  const InfoCodigoPostal({
    required this.estado,
    required this.ciudad,
    required this.colonias,
  });

  factory InfoCodigoPostal.fromJson(Map<String, dynamic> json) => InfoCodigoPostal(
    estado: json['estado']?.toString() ?? '',
    ciudad: json['ciudad']?.toString() ?? json['municipio']?.toString() ?? '',
    colonias: (json['colonias'] as List<dynamic>? ?? []).map((c) => c.toString()).toList(),
  );

  final String estado;
  final String ciudad;
  final List<String> colonias;
}

class CodigoPostalService {
  String get _baseUrl => ApiConfig.baseUrl;

  /// Busca [cp] contra el catálogo real de códigos postales. Lanza
  /// [CodigoPostalException] si el formato es inválido o si ese código
  /// postal simplemente no existe en México.
  Future<InfoCodigoPostal> buscar(String cp) async {
    final response = await withTimeout(http.get(Uri.parse('$_baseUrl/codigos-postales/$cp')));
    if (response.statusCode == 404) {
      throw CodigoPostalException('Ese código postal no existe');
    }
    if (response.statusCode != 200) {
      String mensaje = 'No se pudo validar el código postal';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] is String) mensaje = body['message'] as String;
      } catch (_) {}
      throw CodigoPostalException(mensaje);
    }
    return InfoCodigoPostal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
