import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido_admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';

class ActualizarEstadoScreen extends StatefulWidget {
  const ActualizarEstadoScreen({super.key, required this.pedido});

  final PedidoAdmin pedido;

  @override
  State<ActualizarEstadoScreen> createState() => _ActualizarEstadoScreenState();
}

class _ActualizarEstadoScreenState extends State<ActualizarEstadoScreen> {
  late PedidoEstado _seleccionado = widget.pedido.estado;
  bool _isSaving = false;

  bool _esTransicionValida(PedidoEstado actual, PedidoEstado destino) {
    if (actual == destino) return true;

    // Final states cannot transition to anything
    if (actual == PedidoEstado.entregado || actual == PedidoEstado.cancelado) {
      return false;
    }

    // Any active state can transition to 'atencion' (to raise an alert)
    if (destino == PedidoEstado.atencion) {
      return true;
    }

    // If currently in 'atencion', can transition to any operational state to resolve it
    if (actual == PedidoEstado.atencion) {
      return destino != PedidoEstado.cancelado && destino != PedidoEstado.entregado;
    }

    switch (actual) {
      case PedidoEstado.recibido:
        return destino == PedidoEstado.asignado || destino == PedidoEstado.enPlanta;
      case PedidoEstado.asignado:
        return destino == PedidoEstado.enPlanta;
      case PedidoEstado.enPlanta:
        return destino == PedidoEstado.lavando;
      case PedidoEstado.lavando:
        return destino == PedidoEstado.secandoDoblado;
      case PedidoEstado.secandoDoblado:
        return destino == PedidoEstado.listo || destino == PedidoEstado.enCamino;
      case PedidoEstado.listo:
        return destino == PedidoEstado.enCamino || destino == PedidoEstado.entregado;
      case PedidoEstado.enCamino:
        return destino == PedidoEstado.entregado;
      default:
        return false;
    }
  }

  bool _deberiaMostrarEstado(PedidoEstado actual, PedidoEstado estado) {
    if (estado == PedidoEstado.cancelado) {
      return actual == PedidoEstado.cancelado;
    }
    if (estado == PedidoEstado.atencion) {
      return actual == PedidoEstado.atencion || (actual != PedidoEstado.entregado && actual != PedidoEstado.cancelado);
    }
    return true;
  }

  Future<void> _guardar(BuildContext context, PedidoAdmin currentPedido) async {
    setState(() => _isSaving = true);
    try {
      await context.read<AdminProvider>().updatePedidoEstado(currentPedido.id, _seleccionado);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a: ${estadoToString(_seleccionado)}')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el estado, intenta de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPedido = context.watch<AdminProvider>().pedidos.firstWhere(
          (p) => p.id == widget.pedido.id,
          orElse: () => widget.pedido,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Actualizar Estado',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pedido ${currentPedido.numero} • ${currentPedido.clienteNombre}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // Resumen del servicio
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del Servicio',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildResumenRow('Servicio', currentPedido.servicioNombre),
                    const SizedBox(height: 8),
                    _buildResumenRow('Artículos', '${currentPedido.items.length} artículo(s)'),
                    if (currentPedido.detallesAdicionales != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentPedido.detallesAdicionales!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Progreso del Servicio',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Seleccione la etapa actual en la que se encuentra la ropa del cliente:',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Builder(
                  builder: (context) {
                    final estadosAMostrar = PedidoEstado.values
                        .where((e) => _deberiaMostrarEstado(currentPedido.estado, e))
                        .toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: estadosAMostrar.length,
                      itemBuilder: (context, index) {
                        final estado = estadosAMostrar[index];
                        final isSelected = _seleccionado == estado;
                        final esValida = _esTransicionValida(currentPedido.estado, estado);
                        return Column(
                          children: [
                            RadioListTile<PedidoEstado>.adaptive(
                              value: estado,
                              groupValue: _seleccionado,
                              activeColor: AppColors.primary,
                              onChanged: esValida
                                  ? (val) {
                                      if (val != null) setState(() => _seleccionado = val);
                                    }
                                  : null,
                              secondary: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryFixed
                                      : (esValida
                                          ? AppColors.surfaceContainer
                                          : AppColors.surfaceContainer.withValues(alpha: 0.4)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  iconoParaEstado(estado),
                                  color: isSelected
                                      ? AppColors.primary
                                      : (esValida
                                          ? AppColors.onSurfaceVariant
                                          : AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                estadoToString(estado),
                                style: GoogleFonts.inter(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: esValida
                                      ? AppColors.onSurface
                                      : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                              ),
                              subtitle: Text(
                                subtituloParaEstado(estado),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: esValida
                                      ? AppColors.onSurfaceVariant
                                      : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            if (index < estadosAMostrar.length - 1)
                              const Divider(color: AppColors.surfaceVariant, height: 1),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _guardar(context, currentPedido),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        ),
      ],
    );
  }
}
