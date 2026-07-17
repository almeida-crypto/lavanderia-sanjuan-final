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
}
