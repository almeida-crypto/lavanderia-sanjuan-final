import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido_admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';
import '../pedido/order_detail_screen.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final pedidos = admin.pedidos;

    // Filtrar pedidos según el chip activo y la búsqueda
    final filteredPedidos = pedidos.where((pedido) {
      // 1. Filtrar por búsqueda
      final query = _searchController.text.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          pedido.id.toLowerCase().contains(query) ||
          pedido.clienteNombre.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      // 2. Filtrar por chip de estado
      switch (_selectedFilter) {
        case 'Recibidos':
          return pedido.estado == PedidoEstado.recibido || pedido.estado == PedidoEstado.asignado;
        case 'En Proceso':
          return pedido.estado == PedidoEstado.enPlanta ||
              pedido.estado == PedidoEstado.lavando ||
              pedido.estado == PedidoEstado.secandoDoblado;
        case 'Listo':
          return pedido.estado == PedidoEstado.enCamino || pedido.estado == PedidoEstado.listo;
        case 'Entregados':
          return pedido.estado == PedidoEstado.entregado;
        case 'Atención':
          return pedido.estado == PedidoEstado.atencion;
        case 'Todos':
        default:
          return true;
      }
    }).toList();

    return Column(
      children: [
        // Top Search and Filtering Area
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pedidos',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              // Search input with prefix search icon
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar pedido (ej. #ORD-1042)',
                  hintStyle: GoogleFonts.inter(color: AppColors.outline),
                  prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.outline),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    'Todos',
                    'Recibidos',
                    'En Proceso',
                    'Listo',
                    'Entregados',
                    'Atención',
                  ].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          }
                        },
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceContainer,
                        checkmarkColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Order List
        Expanded(
          child: admin.isLoading && pedidos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : admin.error != null && pedidos.isEmpty
                  ? Center(
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
                    )
                  : filteredPedidos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: AppColors.outline),
                              const SizedBox(height: 12),
                              Text(
                                'No se encontraron pedidos',
                                style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: admin.cargarPedidos,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredPedidos.length,
                            itemBuilder: (context, index) {
                              final pedido = filteredPedidos[index];
                              return _buildOrderListItem(context, pedido);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildOrderListItem(BuildContext context, PedidoAdmin pedido) {
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
      case PedidoEstado.enPlanta:
      case PedidoEstado.secandoDoblado:
        tagBg = AppColors.surfaceContainer;
        tagText = AppColors.primary;
        tagLabel = estadoToString(pedido.estado);
        break;
      case PedidoEstado.recibido:
        tagBg = AppColors.primaryFixed;
        tagText = AppColors.onPrimaryFixedVariant;
        tagLabel = 'Recibido';
        break;
      case PedidoEstado.asignado:
        tagBg = AppColors.secondaryContainer;
        tagText = AppColors.onSecondaryContainer;
        tagLabel = 'Repartidor Asignado';
        break;
      case PedidoEstado.listo:
      case PedidoEstado.enCamino:
        tagBg = AppColors.primaryFixed;
        tagText = AppColors.primary;
        tagLabel = estadoToString(pedido.estado);
        break;
      case PedidoEstado.entregado:
        tagBg = AppColors.surfaceContainerHigh;
        tagText = AppColors.secondary;
        tagLabel = 'Entregado';
        break;
      case PedidoEstado.cancelado:
        tagBg = AppColors.surfaceContainerHigh;
        tagText = AppColors.outline;
        tagLabel = 'Cancelado';
        break;
    }

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

    final isWarning = pedido.estado == PedidoEstado.atencion && pedido.warningMessage != null;

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pedido.id,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pedido.clienteNombre,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
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
                        fontWeight: FontWeight.bold,
                        color: tagText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Service details container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        getServiceIcon(pedido.servicioIcono),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pedido.servicioNombre,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pedido.repartidorNombre != null
                                ? 'Repartidor: ${pedido.repartidorNombre} • Domicilio'
                                : 'Entrega: ${pedido.tipoEntrega}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (isWarning) ...[
                const SizedBox(height: 12),
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
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (pedido.estado == PedidoEstado.lavando ||
                  pedido.estado == PedidoEstado.enPlanta ||
                  pedido.estado == PedidoEstado.secandoDoblado ||
                  pedido.estado == PedidoEstado.asignado) ...[
                const SizedBox(height: 12),
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
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],

              // Card Bottom actions
              const SizedBox(height: 12),
              const Divider(color: AppColors.surfaceVariant),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      pedido.estado == PedidoEstado.entregado ? 'Ver recibo' : 'Ver detalle',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
