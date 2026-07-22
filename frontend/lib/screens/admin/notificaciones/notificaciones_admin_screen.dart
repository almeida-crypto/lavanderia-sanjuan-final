import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/pedido_admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notificaciones_store.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/notificacion_filtro_menu.dart';
import '../../../widgets/notificacion_swipe_tile.dart';
import '../pedido/order_detail_screen.dart';

class NotificacionesAdminScreen extends StatefulWidget {
  const NotificacionesAdminScreen({super.key});

  @override
  State<NotificacionesAdminScreen> createState() =>
      _NotificacionesAdminScreenState();
}

class _NotificacionesAdminScreenState
    extends State<NotificacionesAdminScreen> with WidgetsBindingObserver {
  Timer? _actualizador;
  NotificacionesStore? _store;
  VistaNotificaciones _vista = VistaNotificaciones.activas;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AdminProvider>().cargarPedidos();
    _cargarStore();
    _actualizador = Timer.periodic(
      const Duration(seconds: 20),
      (_) => context.read<AdminProvider>().cargarPedidos(),
    );
  }

  Future<void> _cargarStore() async {
    final usuarioId = context.read<AuthProvider>().currentUser?.id;
    final store = NotificacionesStore(namespace: 'admin', usuarioId: usuarioId);
    await store.cargar();
    if (!mounted) return;
    setState(() => _store = store);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AdminProvider>().cargarPedidos();
    }
  }

  @override
  void dispose() {
    _actualizador?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _claveDe(PedidoAdmin pedido) => 'pedido_${pedido.id}_${pedido.estado.name}';

  void _abrir(PedidoAdmin pedido) {
    _store?.marcarLeida(_claveDe(pedido));
    setState(() {});
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(pedido: pedido)),
    );
  }

  void _marcarTodoLeido(List<PedidoAdmin> pedidos) {
    final store = _store;
    if (store == null) return;
    store.marcarTodoLeido(pedidos.map(_claveDe));
    setState(() {});
  }

  void _archivar(PedidoAdmin pedido) {
    final store = _store;
    if (store == null) return;
    final clave = _claveDe(pedido);
    store.archivar(clave);
    setState(() {});
    _messengerKey.currentState?.showSnackBar(SnackBar(
      content: const Text('Notificación archivada'),
      action: SnackBarAction(
        label: 'Deshacer',
        onPressed: () {
          store.desarchivar(clave);
          setState(() {});
        },
      ),
    ));
  }

  void _eliminar(PedidoAdmin pedido) {
    final store = _store;
    if (store == null) return;
    final clave = _claveDe(pedido);
    store.eliminar(clave);
    setState(() {});
    _messengerKey.currentState?.showSnackBar(SnackBar(
      content: const Text('Notificación eliminada'),
      action: SnackBarAction(
        label: 'Deshacer',
        onPressed: () {
          store.restaurar(clave);
          setState(() {});
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final store = _store;
    final pedidos = [...admin.pedidos]
      ..sort(
        (a, b) => (b.creadoEn ?? DateTime(0)).compareTo(
          a.creadoEn ?? DateTime(0),
        ),
      );

    final activos = store == null
        ? pedidos
        : pedidos.where((p) {
            final clave = _claveDe(p);
            return !store.eliminadas.contains(clave) && !store.archivadas.contains(clave);
          }).toList();
    final leidos = store == null
        ? <PedidoAdmin>[]
        : activos.where((p) => store.leidas.contains(_claveDe(p))).toList();
    final archivados = store == null
        ? <PedidoAdmin>[]
        : pedidos.where((p) {
            final clave = _claveDe(p);
            return !store.eliminadas.contains(clave) && store.archivadas.contains(clave);
          }).toList();
    final visibles = switch (_vista) {
      VistaNotificaciones.activas => activos,
      VistaNotificaciones.leidas => leidos,
      VistaNotificaciones.archivadas => archivados,
    };
    final hayNoLeidas = store != null && activos.any((p) => !store.leidas.contains(_claveDe(p)));
    final esVistaArchivadas = _vista == VistaNotificaciones.archivadas;

    // ScaffoldMessenger propio: sin esto, el snackbar de "Deshacer" (con su
    // botón activo) se queda visible sobre la pantalla anterior al volver
    // atrás, porque por defecto toda la app comparte un único
    // ScaffoldMessenger. Un toque ahí podía deshacer una eliminación sin
    // querer, dando la sensación de que "no funciona".
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
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
              onPressed: () => _marcarTodoLeido(activos),
              child: Text(
                'Marcar Todo Leído',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          NotificacionFiltroMenu(
            vista: _vista,
            onChanged: (v) => setState(() => _vista = v),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: admin.cargarPedidos,
        child: admin.isLoading && visibles.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : visibles.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 220),
                      Center(
                        child: Text(switch (_vista) {
                          VistaNotificaciones.archivadas => 'No hay notificaciones archivadas',
                          VistaNotificaciones.leidas => 'No hay notificaciones leídas',
                          VistaNotificaciones.activas => 'No hay actividad de pedidos',
                        }),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: visibles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pedido = visibles[index];
                      if (esVistaArchivadas) {
                        return _NotificacionArchivadaCard(
                          pedido: pedido,
                          onRestaurar: () {
                            _store?.desarchivar(_claveDe(pedido));
                            setState(() {});
                          },
                        );
                      }
                      final leida = store?.leidas.contains(_claveDe(pedido)) ?? false;
                      return NotificacionSwipeTile(
                        notifKey: _claveDe(pedido),
                        onSwipe: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            _eliminar(pedido);
                          } else {
                            _archivar(pedido);
                          }
                        },
                        child: _NotificacionPedidoCard(
                          pedido: pedido,
                          leida: leida,
                          onTap: () => _abrir(pedido),
                        ),
                      );
                    },
                  ),
      ),
      ),
    );
  }
}

class _NotificacionPedidoCard extends StatelessWidget {
  const _NotificacionPedidoCard({required this.pedido, required this.leida, required this.onTap});

  final PedidoAdmin pedido;
  final bool leida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgente = pedido.tieneReporteAbierto;
    final nuevo = pedido.estado == PedidoEstado.recibido;
    final color = urgente ? AppColors.error : AppColors.primary;
    final icono = urgente
        ? Icons.warning_amber_rounded
        : nuevo
            ? Icons.fiber_new_rounded
            : iconoParaEstado(pedido.estado);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: urgente
              ? AppColors.error.withValues(alpha: 0.45)
              : (leida ? AppColors.surfaceVariant : AppColors.primary.withValues(alpha: 0.3)),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!leida) Container(width: 4, color: AppColors.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icono, color: color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              urgente
                                  ? 'Pedido ${pedido.numero} requiere atención'
                                  : nuevo
                                      ? 'Nuevo pedido ${pedido.numero}'
                                      : 'Pedido ${pedido.numero}: ${estadoToString(pedido.estado)}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              urgente && pedido.warningMessage != null
                                  ? pedido.warningMessage!
                                  : '${pedido.clienteNombre} • ${pedido.servicioNombre}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtituloParaEstado(pedido.estado),
                              style: GoogleFonts.inter(fontSize: 12, color: color),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.onSurfaceVariant,
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
  const _NotificacionArchivadaCard({required this.pedido, required this.onRestaurar});

  final PedidoAdmin pedido;
  final VoidCallback onRestaurar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(iconoParaEstado(pedido.estado), color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido ${pedido.numero}: ${estadoToString(pedido.estado)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  Text(
                    pedido.clienteNombre,
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
