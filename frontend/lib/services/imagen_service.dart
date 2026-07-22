import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../utils/api_config.dart';

class ImagenException implements Exception {
  ImagenException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ImagenService {
  Future<String> subir(XFile archivo, {required String carpeta}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/imagenes'),
    );
    if (ApiConfig.authToken != null) {
      request.headers['Authorization'] = 'Bearer ${ApiConfig.authToken}';
    }
    request.fields['carpeta'] = carpeta;
    // XFile.path puede ser una URL blob en Flutter Web. Los bytes funcionan
    // tanto allí como en Android/iOS.
    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        await archivo.readAsBytes(),
        filename: archivo.name,
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 45));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      var message = 'No se pudo subir la imagen';
      try {
        message = jsonDecode(body)['message']?.toString() ?? message;
      } catch (_) {}
      throw ImagenException(message);
    }
    return jsonDecode(body)['url'].toString();
  }
}
