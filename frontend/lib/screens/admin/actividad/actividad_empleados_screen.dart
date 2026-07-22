import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/pedido_evento.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/pedido_evento_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/tiempo_relativo.dart';

/// Bitácora de actividad: qué empleado/admin/repartidor cambió el estado de
/// cada pedido, quién lo recibió en planta, quién lo entregó y quién asignó
/// al repartidor. Se arma a partir de los eventos que registra el backend en
/// cada acción, no de datos inventados.
class ActividadEmpleadosScreen extends StatefulWidget {
  const ActividadEmpleadosScreen({super.key});

  @override
  State<ActividadEmpleadosScreen> createState() => _ActividadEmpleadosScreenState();
}

class _ActividadEmpleadosScreenState extends State<ActividadEmpleadosScreen> {
  final _service = PedidoEventoService();
  List<PedidoEvento> _eventos = [];
  bool _isLoading = true;
  String? _error;
  String? _actorIdFiltro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().cargarEmpleados();
    });
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final eventos = await _service.listar(actorId: _actorIdFiltro);
      if (!mounted) return;
      setState(() {
        _eventos = eventos;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la actividad. Desliza hacia abajo para reintentar.';
        _isLoading = false;
      });
    }
  }

  IconData _iconoAccion(String accion) {
    switch (accion) {
      case 'pedido_entregado':
        return Icons.task_alt_rounded;
      case 'pedido_recibido_en_planta':
        return Icons.storefront_rounded;
      case 'repartidor_asignado':
        return Icons.two_wheeler_rounded;
      case 'precio_confirmado':
        return Icons.payments_rounded;
      default:
        return Icons.sync_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final empleados = context.watch<AdminProvider>().empleados;
    final nombreFiltro = _actorIdFiltro == null
        ? null
        : empleados.where((e) => e.id == _actorIdFiltro).map((e) => e.nombre).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Actividad de Empleados',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        actions: [
          PopupMenuButton<String?>(
            tooltip: 'Filtrar por empleado',
            icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
            onSelected: (id) {
              setState(() => _actorIdFiltro = id);
              _cargar();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Todos')),
              for (final e in empleados)
                PopupMenuItem(value: e.id, child: Text(e.nombre, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (nombreFiltro != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('Filtrando por: $nombreFiltro'),
                  onDeleted: () {
                    setState(() => _actorIdFiltro = null);
                    _cargar();
                  },
                  backgroundColor: AppColors.primaryFixed,
                  labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _cargar,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
                          ),
                        if (_eventos.isEmpty && _error == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 80),
                            child: Center(
                              child: Text(
                                'Todavía no hay actividad registrada',
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          )
                        else
                          for (var i = 0; i < _eventos.length; i++) ...[
                            _EventoCard(evento: _eventos[i], icono: _iconoAccion(_eventos[i].accion)),
                            if (i != _eventos.length - 1) const SizedBox(height: 12),
                          ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.evento, required this.icono});

  final PedidoEvento evento;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
            child: Icon(icono, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        evento.actorNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tiempoRelativo(evento.creadoEn),
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                if (evento.actorRol != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      etiquetaRol(evento.actorRol),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  evento.detalle?.isNotEmpty == true ? evento.detalle! : etiquetaAccion(evento.accion),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                if (evento.pedidoNumeroTexto.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Pedido ${evento.pedidoNumeroTexto}'
                    '${evento.clienteNombre != null ? ' · ${evento.clienteNombre}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
