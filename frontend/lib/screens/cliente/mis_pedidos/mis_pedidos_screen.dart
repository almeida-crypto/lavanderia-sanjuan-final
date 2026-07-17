import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/pedido.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pedido_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../agendar_recoleccion/agendar_recoleccion_screen.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../pedido/pedido_screen.dart';
import '../servicios/servicios_screen.dart';
import 'detalle_factura_screen.dart';

class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({super.key});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  final _pedidoService = PedidoService();
  bool _isLoading = true;
  String? _error;
  final List<Pedido> _pedidos = [];

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _pedidoService.listarPedidos(clienteId: auth.currentUser?.id);
      setState(() {
        _pedidos
          ..clear()
          ..addAll(data.map(Pedido.fromJson));
      });
    } catch (_) {
      setState(() => _error = 'No se pudieron cargar los pedidos');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onTabSelected(BuildContext context, AppBottomTab tab) {
    switch (tab) {
      case AppBottomTab.home:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeClienteScreen()),
        );
      case AppBottomTab.services:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ServiciosScreen()),
        );
      case AppBottomTab.orders:
        break;
      case AppBottomTab.profile:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MiPerfilScreen()),
        );
    }
  }

  void _verDetalles(BuildContext context, Pedido pedido) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PedidoScreen(pedido: pedido)),
    );
  }

  void _repetirPedido(BuildContext context, Pedido pedido) {
    Navigator.of(context).push(
      AgendarRecoleccionScreen.route(servicioInicial: pedido.tipoServicio),
    );
  }

  void _verFactura(BuildContext context, Pedido pedido) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetalleFacturaScreen(pedido: pedido)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Mis Pedidos',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _cargarPedidos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  )
                else if (_pedidos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Aún no tienes pedidos registrados.',
                      style: GoogleFonts.inter(color: AppColors.secondary),
                    ),
                  )
                else
                  for (var i = 0; i < _pedidos.length; i++) ...[
                    _PedidoCard(
                      pedido: _pedidos[i],
                      onVerDetalles: () => _verDetalles(context, _pedidos[i]),
                      onRepetirPedido: () => _repetirPedido(context, _pedidos[i]),
                      onFactura: () => _verFactura(context, _pedidos[i]),
                    ),
                    if (i != _pedidos.length - 1) const SizedBox(height: 16),
                  ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppBottomTab.orders,
        onTabSelected: (tab) => _onTabSelected(context, tab),
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  const _PedidoCard({
    required this.pedido,
    required this.onVerDetalles,
    required this.onRepetirPedido,
    required this.onFactura,
  });

  final Pedido pedido;
  final VoidCallback onVerDetalles;
  final VoidCallback onRepetirPedido;
  final VoidCallback onFactura;

  @override
  Widget build(BuildContext context) {
    final enProceso = pedido.estado == EstadoPedido.enProceso;
    final cancelado = pedido.estado == EstadoPedido.cancelado;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryContainer),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pedido.numero,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pedido.servicio,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              _EstadoBadge(estado: pedido.estado),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                pedido.fechaFormateada,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.payments_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '\$${pedido.precioFinal.toStringAsFixed(2)} MXN',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              if (!pedido.precioConfirmado) ...[
                const SizedBox(width: 6),
                Text(
                  '(estimado)',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (enProceso)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onVerDetalles,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.primary,
                  side: BorderSide.none,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Ver Detalles',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else if (cancelado)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRepetirPedido,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(
                  'Volver a Pedir',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRepetirPedido,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: Text(
                      'Repetir Pedido',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onFactura,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.secondaryContainer,
                      foregroundColor: AppColors.primary,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, size: 20),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) {
    final (color, icon, texto) = switch (estado) {
      EstadoPedido.enProceso => (AppColors.primaryContainer, Icons.local_laundry_service_rounded, 'En proceso'),
      EstadoPedido.entregado => (AppColors.surfaceContainer, Icons.check_circle_rounded, 'Entregado'),
      EstadoPedido.cancelado => (AppColors.errorContainer, Icons.cancel_rounded, 'Cancelado'),
    };
    final iconColor = estado == EstadoPedido.enProceso
        ? Colors.white
        : estado == EstadoPedido.cancelado
        ? AppColors.onErrorContainer
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            texto,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: iconColor),
          ),
        ],
      ),
    );
  }
}
