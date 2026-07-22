import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/soporte_service.dart';
import '../../utils/app_colors.dart';

class SoporteChatScreen extends StatefulWidget {
  const SoporteChatScreen({super.key, this.clienteId, this.clienteNombre});
  final String? clienteId;
  final String? clienteNombre;

  @override
  State<SoporteChatScreen> createState() => _SoporteChatScreenState();
}

class _SoporteChatScreenState extends State<SoporteChatScreen> {
  final _service = SoporteService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<MensajeSoporte> _mensajes = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargar();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso && mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.mensajes(clienteId: widget.clienteId);
      await _service.marcarLeidos(clienteId: widget.clienteId);
      if (!mounted) return;
      setState(() { _mensajes = data; _loading = false; _error = null; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });
    } catch (_) {
      if (!mounted || silencioso) return;
      setState(() { _loading = false; _error = 'No pudimos conectar con soporte. Revisa tu internet e intenta de nuevo.'; });
    }
  }

  Future<void> _enviar() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.enviar(text, clienteId: widget.clienteId, clienteNombre: widget.clienteNombre);
      _controller.clear();
      await _cargar(silencioso: true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo enviar. Intenta de nuevo.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.clienteNombre == null ? 'Chat con soporte' : widget.clienteNombre!),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _EstadoError(texto: _error!, onRetry: _cargar)
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: _mensajes.isEmpty
                          ? ListView(children: const [SizedBox(height: 130), Icon(Icons.support_agent_rounded, size: 64, color: AppColors.primary), SizedBox(height: 16), Center(child: Text('Cuéntanos en qué podemos ayudarte'))])
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.all(16),
                              itemCount: _mensajes.length,
                              itemBuilder: (_, i) {
                                final m = _mensajes[i];
                                final mio = m.autorId == userId;
                                return Align(
                                  alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 300),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: mio ? AppColors.primary : AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      if (!mio) Text(m.autorNombre, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      Text(m.mensaje, style: GoogleFonts.inter(color: mio ? Colors.white : AppColors.onSurface, height: 1.35)),
                                    ]),
                                  ),
                                );
                              },
                            ),
                    ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, textInputAction: TextInputAction.newline, decoration: const InputDecoration(hintText: 'Escribe un mensaje...', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _sending ? null : _enviar, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _EstadoError extends StatelessWidget {
  const _EstadoError({required this.texto, required this.onRetry});
  final String texto;
  final Future<void> Function({bool silencioso}) onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.onSurfaceVariant), const SizedBox(height: 12), Text(texto, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: () => onRetry(), icon: const Icon(Icons.refresh), label: const Text('Reintentar'))])));
}
