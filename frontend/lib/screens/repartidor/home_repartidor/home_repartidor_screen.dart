import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/pedido_admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notificaciones_store.dart';
import '../../../utils/app_colors.dart';
import '../../auth/login/bienvenida_screen.dart';
import '../notificaciones/notificaciones_repartidor_screen.dart';

class HomeRepartidorScreen extends StatefulWidget {
  const HomeRepartidorScreen({super.key});

  @override
  State<HomeRepartidorScreen> createState() => _HomeRepartidorScreenState();
}

class _HomeRepartidorScreenState extends State<HomeRepartidorScreen> {
  int _selectedTab = 0; // 0: Recolecciones, 1: Entregas, 2: Completados
  int _notificacionesNoLeidas = 0;

  String _claveDe(PedidoAdmin pedido) => 'pedido_${pedido.id}_${pedido.estado.name}';

  bool _esPendiente(PedidoAdmin p) =>
      p.estado == PedidoEstado.asignado ||
      p.estado == PedidoEstado.listo ||
      p.estado == PedidoEstado.enCamino;

  Future<void> _actualizarNotificaciones() async {
    final usuario = context.read<AuthProvider>().currentUser;
    final store = NotificacionesStore(namespace: 'repartidor', usuarioId: usuario?.id);
    await store.cargar();
    final pedidos = context.read<AdminProvider>().pedidos.where(
          (p) => usuario != null && p.repartidorId == usuario.id && _esPendiente(p),
        );
    final cantidad = pedidos.where((pedido) {
      final clave = _claveDe(pedido);
      return !store.leidas.contains(clave) &&
          !store.archivadas.contains(clave) &&
          !store.eliminadas.contains(clave);
    }).length;
    if (mounted) setState(() => _notificacionesNoLeidas = cantidad);
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    context.read<AdminProvider>().limpiar();
    await context.read<AuthProvider>().logout(context);
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BienvenidaScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().cargarPedidos().whenComplete(_actualizarNotificaciones);
    });
  }

  Future<void> _actualizarEstado(PedidoAdmin pedido, PedidoEstado nuevoEstado) async {
    try {
      await context.read<AdminProvider>().updatePedidoEstado(pedido.id, nuevoEstado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido ${pedido.numero} actualizado con éxito'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el pedido. Intenta de nuevo.')),
      );
    }
  }

  void _confirmarCambioEstado({
    required BuildContext context,
    required PedidoAdmin pedido,
    required PedidoEstado nuevoEstado,
    required String titulo,
    required String mensaje,
    required String textoBoton,
    required Color colorBoton,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            titulo,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            mensaje,
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _actualizarEstado(pedido, nuevoEstado);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBoton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                textoBoton,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.outline),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar tus pedidos',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.read<AdminProvider>().cargarPedidos(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().currentUser;
    final adminProvider = context.watch<AdminProvider>();
    final todosPedidos = adminProvider.pedidos;
    final pedidosAsignados = todosPedidos
        .where((pedido) => usuario != null && pedido.repartidorId == usuario.id)
        .toList();

    // La API ya devuelve únicamente los pedidos del repartidor autenticado;
    // este filtro adicional evita mostrar datos previos mientras se refresca
    // una sesión que cambió de usuario en el mismo dispositivo.
    final recolecciones = pedidosAsignados.where((p) {
      return p.estado == PedidoEstado.asignado;
    }).toList();

    final entregas = pedidosAsignados.where((p) {
      return p.estado == PedidoEstado.listo || p.estado == PedidoEstado.enCamino;
    }).toList();

    final completados = pedidosAsignados.where((p) {
      return p.estado == PedidoEstado.entregado;
    }).toList();

    final pedidosActuales = _selectedTab == 0
        ? recolecciones
        : (_selectedTab == 1 ? entregas : completados);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de Repartidor',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  usuario?.nombre ?? 'Repartidor',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificacionesRepartidorScreen(),
                    ),
                  );
                  await _actualizarNotificaciones();
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
              ),
              if (_notificacionesNoLeidas > 0)
                Positioned(
                  right: 5,
                  top: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _notificacionesNoLeidas > 9 ? '9+' : '$_notificacionesNoLeidas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Actualizar pedidos',
            onPressed: adminProvider.isLoading
                ? null
                : () => context.read<AdminProvider>().cargarPedidos().whenComplete(_actualizarNotificaciones),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _cerrarSesion(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTabItem(0, 'Recoger (${recolecciones.length})', Icons.assignment_return_outlined),
                    _buildTabItem(1, 'Entregar (${entregas.length})', Icons.local_shipping_outlined),
                    _buildTabItem(2, 'Completados (${completados.length})', Icons.check_circle_outline),
                  ],
                ),
              ),
            ),

            // Order List
            Expanded(
              child: adminProvider.isLoading && pedidosAsignados.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : adminProvider.error != null && pedidosAsignados.isEmpty
                      ? _buildErrorState(context, adminProvider.error!)
                      : pedidosActuales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedTab == 0
                                ? Icons.inbox_outlined
                                : (_selectedTab == 1
                                    ? Icons.local_shipping_outlined
                                    : Icons.task_alt_outlined),
                            size: 56,
                            color: AppColors.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 0
                                ? 'No hay recolecciones pendientes'
                                : (_selectedTab == 1
                                    ? 'No hay entregas pendientes'
                                    : 'No hay pedidos completados'),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: pedidosActuales.length,
                      itemBuilder: (context, index) {
                        final pedido = pedidosActuales[index];
                        return _buildOrderCard(context, pedido);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, PedidoAdmin pedido) {
    final esRecoleccion = _selectedTab == 0;
    final esEntrega = _selectedTab == 1;
    final entregaEnCamino = pedido.estado == PedidoEstado.enCamino;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pedido ${pedido.numero}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  pedido.fecha,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Client Name
            Row(
              children: [
                const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pedido.clienteNombre,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Servicio (qué se va a recoger/entregar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_laundry_service_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    pedido.servicioNombre,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Location / Address (Prominent requirement)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubicación de ${esRecoleccion ? 'Recolección' : 'Entrega'}:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pedido.clienteDireccion,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Phone & Payment method
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  pedido.clienteTelefono,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (pedido.metodoPago != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pedido.metodoPago!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            if (pedido.detallesAdicionales != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pedido.detallesAdicionales!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(color: AppColors.surfaceVariant, height: 1),
            const SizedBox(height: 16),

            // Action Buttons
            if (esRecoleccion)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _confirmarCambioEstado(
                      context: context,
                      pedido: pedido,
                      nuevoEstado: PedidoEstado.enPlanta,
                      titulo: 'Confirmar Recolección',
                      mensaje: '¿Confirmas que ya recogiste las prendas del cliente "${pedido.clienteNombre}"?',
                      textoBoton: 'Marcar como Recogido',
                      colorBoton: AppColors.primary,
                    );
                  },
                  icon: const Icon(Icons.archive_outlined, size: 20),
                  label: Text(
                    'MARCAR COMO RECOGIDO',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

            if (esEntrega)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _confirmarCambioEstado(
                      context: context,
                      pedido: pedido,
                      nuevoEstado: entregaEnCamino ? PedidoEstado.entregado : PedidoEstado.enCamino,
                      titulo: entregaEnCamino ? 'Confirmar Entrega' : 'Iniciar Entrega',
                      mensaje: entregaEnCamino
                          ? '¿Confirmas que entregaste las prendas al cliente "${pedido.clienteNombre}"?'
                          : '¿Confirmas que vas en camino a entregar las prendas a "${pedido.clienteNombre}"?',
                      textoBoton: entregaEnCamino ? 'Marcar como Entregado' : 'Iniciar Entrega',
                      colorBoton: entregaEnCamino ? Colors.green.shade700 : AppColors.primary,
                    );
                  },
                  icon: Icon(
                    entregaEnCamino ? Icons.check_circle_outline : Icons.local_shipping_outlined,
                    size: 20,
                  ),
                  label: Text(
                    entregaEnCamino ? 'MARCAR COMO ENTREGADO' : 'INICIAR ENTREGA',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: entregaEnCamino ? Colors.green.shade700 : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

            if (!esRecoleccion && !esEntrega)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pedido Completado y Entregado',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
