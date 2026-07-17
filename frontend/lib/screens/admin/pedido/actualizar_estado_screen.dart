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
                'Pedido ${currentPedido.id} • ${currentPedido.clienteNombre}',
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
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: PedidoEstado.values.map((estado) {
                    // Omitir "atención"/"cancelado" si no son el estado actual: no son
                    // etapas normales del flujo, "atención" es una alerta y "cancelado"
                    // lo dispara el cliente, no una elección manual del admin.
                    if ((estado == PedidoEstado.atencion || estado == PedidoEstado.cancelado) &&
                        currentPedido.estado != estado) {
                      return const SizedBox.shrink();
                    }

                    final isSelected = _seleccionado == estado;
                    return Column(
                      children: [
                        RadioListTile<PedidoEstado>.adaptive(
                          value: estado,
                          groupValue: _seleccionado,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            if (val != null) setState(() => _seleccionado = val);
                          },
                          secondary: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryFixed : AppColors.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconoParaEstado(estado),
                              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            estadoToString(estado),
                            style: GoogleFonts.inter(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            subtituloParaEstado(estado),
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ),
                        if (estado != PedidoEstado.values.last)
                          const Divider(color: AppColors.surfaceVariant, height: 1),
                      ],
                    );
                  }).toList(),
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
