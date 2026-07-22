import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/pedido.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notificaciones_store.dart';
import '../../../services/pedido_service.dart';
import '../../../services/promocion_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/notificacion_filtro_menu.dart';
import '../../../widgets/notificacion_swipe_tile.dart';
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
  NotificacionesStore? _store;
  bool _isLoading = true;
  VistaNotificaciones _vista = VistaNotificaciones.activas;
  Timer? _actualizador;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
    _actualizador = Timer.periodic(const Duration(seconds: 20), (_) => _cargar(silencioso: true));
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
    final usuarioId = auth.currentUser?.id;
    final store = _store ?? NotificacionesStore(namespace: 'cliente', usuarioId: usuarioId);
    await store.cargar();
    _store = store;

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
          leida: store.leidas.contains(clave),
        ));
      }
    } catch (_) {
      // Sin promociones disponibles por ahora; no bloquea el resto de la lista.
    }

    try {
      final data = await _pedidoService.listarPedidos(clienteId: auth.currentUser?.id);
      for (final json in data) {
        final pedido = Pedido.fromJson(json);
        final notificacion = _notificacionParaPedido(pedido, store);
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

  Notificacion? _notificacionParaPedido(Pedido pedido, NotificacionesStore store) {
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
          leida: store.leidas.contains(clave),
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
          leida: store.leidas.contains(clave),
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
          leida: store.leidas.contains(clave),
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
          leida: store.leidas.contains(clave),
        );
    }
  }

  void _abrirNotificacion(Notificacion notificacion) {
    final store = _store;
    if (store != null) store.marcarLeida(notificacion.clave);
    setState(() {
      final idx = _notificaciones.indexWhere((n) => n.clave == notificacion.clave);
      if (idx != -1) _notificaciones[idx] = _notificaciones[idx].copyWith(leida: true);
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificacionDetalleScreen(notificacion: notificacion.copyWith(leida: true)),
      ),
    );
  }

  void _marcarTodoLeido() {
    final store = _store;
    if (store == null) return;
    store.marcarTodoLeido(_notificaciones.map((n) => n.clave));
    setState(() {
      for (var i = 0; i < _notificaciones.length; i++) {
        _notificaciones[i] = _notificaciones[i].copyWith(leida: true);
      }
    });
  }

  void _archivar(Notificacion n) {
    final store = _store;
    if (store == null) return;
    store.archivar(n.clave);
    setState(() {});
    _messengerKey.currentState?.showSnackBar(SnackBar(
      content: const Text('Notificación archivada'),
      action: SnackBarAction(
        label: 'Deshacer',
        onPressed: () {
          store.desarchivar(n.clave);
          setState(() {});
        },
      ),
    ));
  }

  void _eliminar(Notificacion n) {
    final store = _store;
    if (store == null) return;
    store.eliminar(n.clave);
    setState(() {});
    _messengerKey.currentState?.showSnackBar(SnackBar(
      content: const Text('Notificación eliminada'),
      action: SnackBarAction(
        label: 'Deshacer',
        onPressed: () {
          store.restaurar(n.clave);
          setState(() {});
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final activas = store == null
        ? _notificaciones
        : _notificaciones.where((n) => !store.eliminadas.contains(n.clave) && !store.archivadas.contains(n.clave)).toList();
    final leidas = activas.where((n) => n.leida).toList();
    final archivadas = store == null
        ? <Notificacion>[]
        : _notificaciones.where((n) => !store.eliminadas.contains(n.clave) && store.archivadas.contains(n.clave)).toList();
    final visibles = switch (_vista) {
      VistaNotificaciones.activas => activas,
      VistaNotificaciones.leidas => leidas,
      VistaNotificaciones.archivadas => archivadas,
    };
    final hayNoLeidas = activas.any((n) => !n.leida);
    final esVistaArchivadas = _vista == VistaNotificaciones.archivadas;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
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
          tituloParaVista(_vista),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (_vista == VistaNotificaciones.activas && hayNoLeidas)
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
          NotificacionFiltroMenu(
            vista: _vista,
            onChanged: (v) => setState(() => _vista = v),
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
                child: visibles.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Text(
                                switch (_vista) {
                                  VistaNotificaciones.archivadas => 'No tienes notificaciones archivadas',
                                  VistaNotificaciones.leidas => 'No tienes notificaciones leídas',
                                  VistaNotificaciones.activas => 'No tienes notificaciones',
                                },
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
                            for (var i = 0; i < visibles.length; i++) ...[
                              esVistaArchivadas
                                  ? _NotificacionArchivadaCard(
                                      notificacion: visibles[i],
                                      onRestaurar: () {
                                        _store?.desarchivar(visibles[i].clave);
                                        setState(() {});
                                      },
                                    )
                                  : NotificacionSwipeTile(
                                      notifKey: visibles[i].clave,
                                      onSwipe: (direction) {
                                        if (direction == DismissDirection.endToStart) {
                                          _eliminar(visibles[i]);
                                        } else {
                                          _archivar(visibles[i]);
                                        }
                                      },
                                      child: _NotificacionCard(
                                        notificacion: visibles[i],
                                        onTap: () => _abrirNotificacion(visibles[i]),
                                      ),
                                    ),
                              if (i != visibles.length - 1) const SizedBox(height: 16),
                            ],
                          ],
                        ),
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

class _NotificacionArchivadaCard extends StatelessWidget {
  const _NotificacionArchivadaCard({required this.notificacion, required this.onRestaurar});

  final Notificacion notificacion;
  final VoidCallback onRestaurar;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: notificacion.iconBg, shape: BoxShape.circle),
              child: Icon(notificacion.icon, color: notificacion.iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificacion.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  Text(
                    notificacion.descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Restaurar',
              icon: const Icon(Icons.unarchive_outlined, color: AppColors.primary),
              onPressed: onRestaurar,
            ),
          ],
        ),
      ),
    );
  }
}
