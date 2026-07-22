import 'package:flutter/material.dart';
import '../../services/soporte_service.dart';
import '../../utils/app_colors.dart';
import 'soporte_chat_screen.dart';

class AdminSoporteScreen extends StatefulWidget {
  const AdminSoporteScreen({super.key});
  @override
  State<AdminSoporteScreen> createState() => _AdminSoporteScreenState();
}

class _AdminSoporteScreenState extends State<AdminSoporteScreen> {
  final _service = SoporteService();
  List<ConversacionSoporte> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.conversaciones();
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'No se pudo cargar soporte. Intenta de nuevo.'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Soporte a clientes'), backgroundColor: AppColors.surface, foregroundColor: AppColors.primary),
    body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _cargar, child: const Text('Reintentar'))]
          else if (_items.isEmpty) const Padding(padding: EdgeInsets.only(top: 120), child: Column(children: [Icon(Icons.mark_chat_read_outlined, size: 60, color: AppColors.primary), SizedBox(height: 12), Text('No hay conversaciones de soporte')]))
          else for (final c in _items) Card(child: ListTile(
            leading: CircleAvatar(child: Text(c.clienteNombre.isEmpty ? 'C' : c.clienteNombre.substring(0, 1).toUpperCase())),
            title: Text(c.clienteNombre),
            subtitle: Text(c.ultimoMensaje, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: c.noLeidos > 0 ? Badge(label: Text('${c.noLeidos}')) : const Icon(Icons.chevron_right),
            onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => SoporteChatScreen(clienteId: c.clienteId, clienteNombre: c.clienteNombre))); _cargar(); },
          )),
        ],
      ),
    ),
  );
}
