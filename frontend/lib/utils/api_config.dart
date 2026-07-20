import 'package:http/http.dart' as http;

/// El backend gratuito de Render se "duerme" tras un rato sin tráfico y
/// tarda hasta medio minuto en despertar en la siguiente petición. Sin un
/// límite de tiempo, las llamadas se quedan esperando indefinidamente y la
/// pantalla parece congelada (botón sin respuesta, sin error, sin nada).
class ServidorLentoException implements Exception {
  const ServidorLentoException();

  @override
  String toString() =>
      'El servidor está tardando en responder (puede estar "despertando"). Intenta de nuevo en unos segundos.';
}

/// Envuelve cualquier llamada http.get/post/put/delete con un límite de
/// tiempo razonable, para que un backend dormido dé un error claro en vez de
/// dejar la pantalla colgada sin ninguna señal de qué está pasando.
Future<http.Response> withTimeout(Future<http.Response> request) {
  return request.timeout(
    const Duration(seconds: 30),
    onTimeout: () => throw const ServidorLentoException(),
  );
}

/// Configuración central de la URL del backend.
class ApiConfig {
  const ApiConfig._();

  /// En producción se define al compilar:
  /// flutter build apk --release \
  ///   --dart-define=API_BASE_URL=https://TU-SERVICIO.onrender.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5162/api',
  );

  /// Token de la sesión activa (lo llena AuthProvider al iniciar sesión o
  /// restaurarla, y lo borra al cerrarla). El backend ahora exige este token
  /// en cada endpoint protegido para saber quién llama y con qué rol, así
  /// que todos los servicios deben mandarlo.
  static String? authToken;

  static Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  static Map<String, String> get authHeaders => {
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };
}
