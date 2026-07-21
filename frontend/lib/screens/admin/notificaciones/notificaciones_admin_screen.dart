import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/pedido_admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AdminProvider>().cargarPedidos();
    _actualizador = Timer.periodic(
      const Duration(seconds: 30),
      (_) => context.read<AdminProvider>().cargarPedidos(),
    );
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

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final pedidos = [...admin.pedidos]
      ..sort(
        (a, b) => (b.creadoEn ?? DateTime(0)).compareTo(
          a.creadoEn ?? DateTime(0),
        ),
      );

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
          'Notificaciones',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: admin.cargarPedidos,
        child: admin.isLoading && pedidos.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : pedidos.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 220),
                      Center(child: Text('No hay actividad de pedidos')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: pedidos.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _NotificacionPedidoCard(pedido: pedidos[index]),
                  ),
      ),
    );
  }
}

class _NotificacionPedidoCard extends StatelessWidget {
  const _NotificacionPedidoCard({required this.pedido});

  final PedidoAdmin pedido;

  @override
  Widget build(BuildContext context) {
    final urgente = pedido.estado == PedidoEstado.atencion;
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
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: urgente
              ? AppColors.error.withValues(alpha: 0.45)
              : AppColors.surfaceVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(pedido: pedido)),
        ),
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
    );
  }
}
