import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/pedido.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pedido_service.dart';
import '../../../services/promocion_service.dart';
import '../../../utils/app_colors.dart';
import 'notificacion_detalle_screen.dart';

enum TipoNotificacion { pedidoRecolectado, promocion, pedidoEntregado, informativa }

/// Notificación derivada de datos reales (pedidos del cliente y la
/// promoción vigente), no de una lista fija. [clave] identifica de forma
/// estable el hecho que la originó (pedido+estado, o promoción), para poder
/// recordar si ya se marcó como leída sin depender de un backend propio de
/// notificaciones.
class Notificacion {
  const Notificacion({
    required this.clave,
    required this.tipo,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.titulo,
    required this.descripcion,
    required this.momento,
    this.leida = false,
  });

  final String clave;
  final TipoNotificacion tipo;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String titulo;
  final String descripcion;
  final DateTime? momento;
  final bool leida;

  String get tiempo => _tiempoRelativo(momento);

  Notificacion copyWith({bool? leida}) => Notificacion(
    clave: clave,
    tipo: tipo,
    icon: icon,
    iconBg: iconBg,
    iconColor: iconColor,
    titulo: titulo,
    descripcion: descripcion,
    momento: momento,
    leida: leida ?? this.leida,
  );
}

String _tiempoRelativo(DateTime? momento) {
  if (momento == null) return '';
  final diff = DateTime.now().difference(momento);
  if (diff.inMinutes < 1) return 'Justo ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ayer';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
  return '${momento.day}/${momento.month}/${momento.year}';
}

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> with WidgetsBindingObserver {
  final _pedidoService = PedidoService();
  final _promocionService = PromocionService();
  final List<Notificacion> _notificaciones = [];
  Set<String> _leidas = {};
  bool _isLoading = true;
  String? _prefsKey;
  Timer? _actualizador;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
    _actualizador = Timer.periodic(const Duration(seconds: 30), (_) => _cargar(silencioso: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar(silencioso: true);
  }

  @override
  void dispose() {
    _actualizador?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso && mounted) setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final usuarioId = auth.currentUser?.id ?? 'anonimo';
    _prefsKey = 'notificaciones_leidas_$usuarioId';

    final prefs = await SharedPreferences.getInstance();
    _leidas = (prefs.getStringList(_prefsKey!) ?? []).toSet();

    final generadas = <Notificacion>[];

    try {
      final promociones = await _promocionService.listar();
      for (final promocion in promociones) {
        if (!promocion.vigente) continue;
        final clave = 'promo_${promocion.id}';
        generadas.add(Notificacion(
          clave: clave,
          tipo: TipoNotificacion.promocion,
          icon: Icons.sell_rounded,
          iconBg: AppColors.secondaryContainer,
          iconColor: AppColors.onSecondaryContainer,
          titulo: promocion.titulo,
          descripcion:
              'Usa el código ${promocion.codigo} para obtener ${promocion.descuentoPorcentaje.toStringAsFixed(0)}% de descuento. ${promocion.descripcion}',
          momento: promocion.fechaInicio,
          leida: _leidas.contains(clave),
        ));
        break;
      }
    } catch (_) {
      // Sin promoción disponible por ahora; no bloquea el resto de la lista.
    }

    try {
      final data = await _pedidoService.listarPedidos(clienteId: auth.currentUser?.id);
      for (final json in data) {
        final pedido = Pedido.fromJson(json);
        final notificacion = _notificacionParaPedido(pedido);
        if (notificacion != null) generadas.add(notificacion);
      }
    } catch (_) {
      // Sin pedidos disponibles por ahora; no bloquea el resto de la lista.
    }

    generadas.sort((a, b) => (b.momento ?? DateTime(0)).compareTo(a.momento ?? DateTime(0)));

    if (!mounted) return;
    setState(() {
      _notificaciones
        ..clear()
        ..addAll(generadas);
      _isLoading = false;
    });
  }

  Notificacion? _notificacionParaPedido(Pedido pedido) {
    final clave = 'pedido_${pedido.id}_${pedido.estado.name}';
    switch (pedido.estado) {
      case EstadoPedido.entregado:
        return Notificacion(
          clave: clave,
          tipo: TipoNotificacion.pedidoEntregado,
          icon: Icons.check_circle_rounded,
          iconBg: AppColors.surfaceContainerHigh,
          iconColor: AppColors.primary,
          titulo: 'Pedido ${pedido.numero} entregado',
          descripcion: 'Tu ropa fue entregada en tu puerta. ¡Gracias por elegir FreshClean!',
          momento: pedido.creadoEn,
          leida: _leidas.contains(clave),
        );
      case EstadoPedido.cancelado:
        return Notificacion(
          clave: clave,
          tipo: TipoNotificacion.informativa,
          icon: Icons.cancel_rounded,
          iconBg: AppColors.errorContainer,
          iconColor: AppColors.error,
          titulo: 'Pedido ${pedido.numero} cancelado',
          descripcion: 'Este pedido fue cancelado.',
          momento: pedido.creadoEn,
          leida: _leidas.contains(clave),
        );
      case EstadoPedido.atencion:
        return Notificacion(
          clave: clave,
          tipo: TipoNotificacion.informativa,
          icon: Icons.warning_amber_rounded,
          iconBg: AppColors.errorContainer,
          iconColor: AppColors.error,
          titulo: 'Pedido ${pedido.numero} necesita tu atención',
          descripcion: 'Hay un reporte pendiente sobre este pedido. Revisa los detalles en Mis Pedidos.',
          momento: pedido.creadoEn,
          leida: _leidas.contains(clave),
        );
      case EstadoPedido.enProceso:
        return Notificacion(
          clave: clave,
          tipo: TipoNotificacion.pedidoRecolectado,
          icon: Icons.local_shipping_rounded,
          iconBg: AppColors.primaryFixed,
          iconColor: AppColors.onPrimaryFixedVariant,
          titulo: 'Pedido ${pedido.numero} en proceso',
          descripcion: 'Tu pedido va en camino a nuestras instalaciones o ya está en proceso. Te avisaremos cuando haya novedades.',
          momento: pedido.creadoEn,
          leida: _leidas.contains(clave),
        );
    }
  }

  Future<void> _guardarLeidas() async {
    if (_prefsKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey!, _leidas.toList());
  }

  void _abrirNotificacion(int index) {
    final clave = _notificaciones[index].clave;
    setState(() => _notificaciones[index] = _notificaciones[index].copyWith(leida: true));
    _leidas.add(clave);
    _guardarLeidas();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificacionDetalleScreen(notificacion: _notificaciones[index]),
      ),
    );
  }

  void _marcarTodoLeido() {
    setState(() {
      for (var i = 0; i < _notificaciones.length; i++) {
        _notificaciones[i] = _notificaciones[i].copyWith(leida: true);
        _leidas.add(_notificaciones[i].clave);
      }
    });
    _guardarLeidas();
  }

  @override
  Widget build(BuildContext context) {
    final hayNoLeidas = _notificaciones.any((n) => !n.leida);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurfaceVariant),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Notificaciones',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (hayNoLeidas)
            TextButton(
              onPressed: _marcarTodoLeido,
              child: Text(
                'Marcar Todo Leído',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: () => _cargar(),
                color: AppColors.primary,
                child: _notificaciones.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Text(
                                'No tienes notificaciones',
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          children: [
                            for (var i = 0; i < _notificaciones.length; i++) ...[
                              _NotificacionCard(
                                notificacion: _notificaciones[i],
                                onTap: () => _abrirNotificacion(i),
                              ),
                              if (i != _notificaciones.length - 1) const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
              ),
      ),
    );
  }
}

class _NotificacionCard extends StatelessWidget {
  const _NotificacionCard({required this.notificacion, required this.onTap});

  final Notificacion notificacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final noLeida = !notificacion.leida;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: noLeida
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.surfaceVariant,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (noLeida) Container(width: 4, color: AppColors.primary),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: notificacion.iconBg, shape: BoxShape.circle),
                  child: Icon(notificacion.icon, color: notificacion.iconColor, size: 22),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notificacion.titulo,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notificacion.tiempo,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: noLeida ? FontWeight.w600 : FontWeight.w400,
                              color: noLeida ? AppColors.primary : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notificacion.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
