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
