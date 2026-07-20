import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido_admin.dart';
import '../../../models/usuario.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_colors.dart';
import '../pedido/order_detail_screen.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, this.onViewOrdersTap});

  final VoidCallback? onViewOrdersTap;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final pedidos = admin.pedidos;
    final isEmpleado = context.watch<AuthProvider>().currentUser?.rol == UserRole.empleado;

    if (admin.isLoading && pedidos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (admin.error != null && pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(admin.error!, style: GoogleFonts.inter(color: AppColors.error)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => admin.cargarPedidos(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Tomamos los primeros 3 pedidos para el resumen reciente
    final pedidosRecientes = pedidos.take(3).toList();

    final ahora = DateTime.now();
    // "Hoy" es cuándo se CREÓ el pedido, no la fecha de recolección que
    // eligió el cliente (esa puede ser cualquier día de la semana entrante).
    final pedidosHoy = pedidos.where((p) {
      final creado = p.creadoEn;
      return creado != null &&
          creado.year == ahora.year &&
          creado.month == ahora.month &&
          creado.day == ahora.day;
    }).length;
    final entregasActivas = pedidos
        .where((p) => p.estado == PedidoEstado.asignado || p.estado == PedidoEstado.enCamino)
        .length;
    final cancelados = pedidos.where((p) => p.estado == PedidoEstado.cancelado).length;
    final ingresos = pedidos
        .where((p) => p.estado != PedidoEstado.cancelado)
        .fold<double>(0, (suma, p) => suma + p.precioFinal);

    return RefreshIndicator(
      onRefresh: admin.cargarPedidos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Text(
            'Panel de Control',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen de actividad para hoy',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Metrics Bento Grid (Flex Row on Desktop, Column/Row on Mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide
                  ? Row(
                      children: [
                        _buildMetricCard(
                          context,
                          title: 'Pedidos de Hoy',
                          value: '$pedidosHoy',
                          icon: Icons.shopping_bag_outlined,
                          iconBg: AppColors.primaryFixed,
                          iconColor: AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                          context,
                          title: 'Entregas Activas',
                          value: '$entregasActivas',
                          icon: Icons.local_shipping_outlined,
                          iconBg: AppColors.secondaryContainer,
                          iconColor: AppColors.onSecondaryContainer,
                          progress: pedidos.isEmpty ? 0 : entregasActivas / pedidos.length,
                        ),
                        const SizedBox(width: 16),
                        if (!isEmpleado) ...[
                          _buildMetricCard(
                            context,
                            title: 'Ingresos',
                            value: '\$${ingresos.toStringAsFixed(2)}',
                            icon: Icons.payments_outlined,
                            iconBg: AppColors.surfaceContainerHigh,
                            iconColor: AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                        ],
                        _buildMetricCard(
                          context,
                          title: 'Cancelados',
                          value: '$cancelados',
                          icon: Icons.cancel_outlined,
                          iconBg: AppColors.errorContainer,
                          iconColor: AppColors.error,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            _buildMetricCard(
                              context,
                              title: 'Pedidos de Hoy',
                              value: '$pedidosHoy',
                              icon: Icons.shopping_bag_outlined,
                              iconBg: AppColors.primaryFixed,
                              iconColor: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            if (!isEmpleado)
                              _buildMetricCard(
                                context,
                                title: 'Ingresos',
                                value: '\$${ingresos.toStringAsFixed(2)}',
                                icon: Icons.payments_outlined,
                                iconBg: AppColors.surfaceContainerHigh,
                                iconColor: AppColors.primary,
                              )
                            else
                              _buildMetricCard(
                                context,
                                title: 'Cancelados',
                                value: '$cancelados',
                                icon: Icons.cancel_outlined,
                                iconBg: AppColors.errorContainer,
                                iconColor: AppColors.error,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildMetricCard(
                              context,
                              title: 'Entregas Activas',
                              value: '$entregasActivas',
                              icon: Icons.local_shipping_outlined,
                              iconBg: AppColors.secondaryContainer,
                              iconColor: AppColors.onSecondaryContainer,
                              progress: pedidos.isEmpty ? 0 : entregasActivas / pedidos.length,
                            ),
                            const SizedBox(width: 12),
                            if (!isEmpleado)
                              _buildMetricCard(
                                context,
                                title: 'Cancelados',
                                value: '$cancelados',
                                icon: Icons.cancel_outlined,
                                iconBg: AppColors.errorContainer,
                                iconColor: AppColors.error,
                              )
                            else
                              const Spacer(),
                          ],
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 32),

          // Recent Orders Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pedidos Recientes',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              TextButton(
                onPressed: onViewOrdersTap,
                child: Text(
                  'Ver Todos',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recent Orders List
          ...pedidosRecientes.map((pedido) => _buildOrderCard(context, pedido)),
        ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    String? badgeText,
    IconData? badgeIcon,
    double? progress,
  }) {
    return Expanded(
      flex: progress != null ? 1 : 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (badgeIcon != null)
                          Icon(badgeIcon, color: AppColors.primaryContainer, size: 14),
                        if (badgeIcon != null) const SizedBox(width: 2),
                        Text(
                          badgeText,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceContainer,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, PedidoAdmin pedido) {
    Color tagBg;
    Color tagText;
    String tagLabel;

    switch (pedido.estado) {
      case PedidoEstado.atencion:
        tagBg = AppColors.errorContainer;
        tagText = AppColors.error;
        tagLabel = 'Atención';
        break;
      case PedidoEstado.lavando:
        tagBg = AppColors.primaryFixed;
        tagText = AppColors.primary;
        tagLabel = 'En Planta';
        break;
      case PedidoEstado.recibido:
        tagBg = AppColors.surfaceContainer;
        tagText = AppColors.onSurfaceVariant;
        tagLabel = 'Recogida Pendiente';
        break;
      default:
        tagBg = AppColors.secondaryContainer;
        tagText = AppColors.onSecondaryContainer;
        tagLabel = estadoToString(pedido.estado);
    }

    final isWarning = pedido.estado == PedidoEstado.atencion && pedido.warningMessage != null;

    IconData getServiceIcon(String iconName) {
      switch (iconName) {
        case 'iron':
          return Icons.iron_outlined;
        case 'dry_cleaning':
          return Icons.dry_cleaning_outlined;
        case 'bed':
          return Icons.bed_outlined;
        case 'scale':
        default:
          return Icons.local_laundry_service_rounded;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isWarning ? AppColors.errorContainer : AppColors.surfaceVariant,
          width: isWarning ? 1.5 : 1,
        ),
      ),
      color: AppColors.surfaceContainerLowest,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(pedido: pedido),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Top: Client & Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceContainer,
                        child: Text(
                          pedido.clienteNombre.substring(0, 1),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pedido.clienteNombre,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            pedido.servicioNombre,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tagLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: tagText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Card Mid details
              if (isWarning)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.errorContainer),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pedido.warningMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (pedido.estado == PedidoEstado.lavando)
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pedido.progreso,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceContainer,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(pedido.progreso * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else if (pedido.detallesAdicionales != null)
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.onSurfaceVariant, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      pedido.detallesAdicionales!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(getServiceIcon(pedido.servicioIcono), color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Entrega por: ${pedido.tipoEntrega}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
