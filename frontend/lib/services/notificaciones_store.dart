import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local de leídas/archivadas/eliminadas por rol y usuario.
/// No hay backend de notificaciones propio: cada pantalla deriva sus
/// notificaciones de datos reales (pedidos, promociones) y esta clase solo
/// recuerda qué hizo el usuario con cada una, para que sobreviva a refrescos
/// y reinicios de la app.
class NotificacionesStore {
  NotificacionesStore({required String namespace, required String? usuarioId})
      : _base = 'notif_${namespace}_${usuarioId ?? 'anonimo'}';

  final String _base;

  Set<String> leidas = {};
  Set<String> archivadas = {};
  Set<String> eliminadas = {};

  String get _leidasKey => '${_base}_leidas';
  String get _archivadasKey => '${_base}_archivadas';
  String get _eliminadasKey => '${_base}_eliminadas';

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    leidas = (prefs.getStringList(_leidasKey) ?? []).toSet();
    archivadas = (prefs.getStringList(_archivadasKey) ?? []).toSet();
    eliminadas = (prefs.getStringList(_eliminadasKey) ?? []).toSet();
  }

  Future<void> _guardar(String key, Set<String> valores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, valores.toList());
  }

  Future<void> marcarLeida(String clave) async {
    if (!leidas.add(clave)) return;
    await _guardar(_leidasKey, leidas);
  }

  Future<void> marcarTodoLeido(Iterable<String> claves) async {
    leidas.addAll(claves);
    await _guardar(_leidasKey, leidas);
  }

  Future<void> archivar(String clave) async {
    archivadas.add(clave);
    await _guardar(_archivadasKey, archivadas);
  }

  Future<void> desarchivar(String clave) async {
    archivadas.remove(clave);
    await _guardar(_archivadasKey, archivadas);
  }

  Future<void> eliminar(String clave) async {
    eliminadas.add(clave);
    await _guardar(_eliminadasKey, eliminadas);
  }

  Future<void> restaurar(String clave) async {
    eliminadas.remove(clave);
    await _guardar(_eliminadasKey, eliminadas);
  }
}
