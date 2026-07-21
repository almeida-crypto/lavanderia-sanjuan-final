import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido_admin.dart';
import '../../../models/usuario.dart';
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
  String? _repartidorId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repartidorId = widget.pedido.repartidorId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().cargarEmpleados();
    });
  }

  Future<void> _guardar(BuildContext context, PedidoAdmin currentPedido) async {
    final admin = context.read<AdminProvider>();
    Usuario? repartidor;
    for (final usuario in admin.empleados) {
      if (usuario.id == _repartidorId && usuario.rol == UserRole.repartidor && usuario.activo) {
        repartidor = usuario;
        break;
      }
    }
    if (_seleccionado == PedidoEstado.asignado && repartidor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un repartidor activo antes de asignar el pedido.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final cambiaRepartidor = repartidor != null && repartidor.id != currentPedido.repartidorId;
      if (cambiaRepartidor) {
        await admin.asignarRepartidor(currentPedido.id, repartidor);
      }

      final estadoFinal = cambiaRepartidor && _seleccionado == PedidoEstado.recibido
          ? PedidoEstado.asignado
          : _seleccionado;
      final estadoActual = cambiaRepartidor ? PedidoEstado.asignado : currentPedido.estado;
      if (estadoFinal != estadoActual) {
        await admin.updatePedidoEstado(currentPedido.id, estadoFinal);
      }
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a: ${estadoToString(estadoFinal)}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      final detalle = error
          .toString()
          .replaceFirst('Exception: ', '')
          .trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            detalle.isEmpty
                ? 'No se pudo actualizar el estado. Intenta de nuevo.'
                : detalle,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final currentPedido = admin.pedidos.firstWhere(
          (p) => p.id == widget.pedido.id,
          orElse: () => widget.pedido,
        );
    final repartidores = admin.empleados
        .where((usuario) => usuario.rol == UserRole.repartidor && usuario.activo)
        .toList();

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
                'Asignación de Repartidor',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'El repartidor asignado verá este pedido en su panel y podrá actualizar sus etapas de ruta.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (admin.isLoadingEmpleados && repartidores.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (repartidores.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No hay repartidores activos. Registra uno desde Configuración de Repartidores.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.onErrorContainer),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: repartidores.any((usuario) => usuario.id == _repartidorId) ? _repartidorId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Repartidor responsable',
                    prefixIcon: Icon(Icons.two_wheeler_rounded),
                  ),
                  hint: const Text('Selecciona un repartidor'),
                  items: repartidores
                      .map(
                        (usuario) => DropdownMenuItem(
                          value: usuario.id,
                          child: Text('${usuario.nombre} · ${usuario.correo}', overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving ? null : (id) => setState(() => _repartidorId = id),
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
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: PedidoEstado.values.length,
                  itemBuilder: (context, index) {
                    final estado = PedidoEstado.values[index];
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
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                        if (index < PedidoEstado.values.length - 1)
                          const Divider(color: AppColors.surfaceVariant, height: 1),
                      ],
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
