import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/pedido.dart';
import '../../../services/pedido_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/telefono_launcher.dart';

/// Seguimiento operativo del pedido.
///
/// La versión anterior dibujaba un mapa y una camioneta ficticios aunque la
/// aplicación no recibe coordenadas GPS. Esta pantalla muestra únicamente
/// información real del backend y permite llamar al repartidor asignado.
class SeguimientoEnVivoScreen extends StatefulWidget {
  const SeguimientoEnVivoScreen({
    super.key,
    required this.pedidoId,
    required this.numeroPedido,
    this.repartidorNombre,
    this.repartidorTelefono,
    this.estado,
    this.direccion,
  });

  final String pedidoId;
  final String numeroPedido;
  final String? repartidorNombre;
  final String? repartidorTelefono;
  final String? estado;
  final String? direccion;

  @override
  State<SeguimientoEnVivoScreen> createState() => _SeguimientoEnVivoScreenState();
}

class _SeguimientoEnVivoScreenState extends State<SeguimientoEnVivoScreen> {
  final _pedidoService = PedidoService();
  late String? _repartidorNombre = widget.repartidorNombre;
  late String? _repartidorTelefono = widget.repartidorTelefono;
  late String _estado = widget.estado ?? 'Pedido recibido';
  late String _direccion = widget.direccion ?? 'Dirección por confirmar';
  bool _actualizando = false;

  Future<void> _refrescar() async {
    if (_actualizando) return;
    setState(() => _actualizando = true);
    try {
      final actualizado = await _pedidoService.obtenerPedido(widget.pedidoId);
      final pedido = Pedido.fromJson(actualizado);
      if (!mounted) return;
      setState(() {
        _repartidorNombre = pedido.repartidorNombre;
        _repartidorTelefono = pedido.repartidorTelefono;
        _estado = pedido.estadoDetalle;
        _direccion = pedido.direccion;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el seguimiento.')),
      );
    } finally {
      if (mounted) setState(() => _actualizando = false);
    }
  }

  Future<void> _llamarRepartidor() async {
    final abierto = await abrirLlamada(_repartidorTelefono);
    if (!mounted || abierto) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _repartidorNombre == null
              ? 'Todavía no hay un repartidor asignado.'
              : 'El repartidor no tiene un teléfono registrado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asignado = _repartidorNombre?.trim().isNotEmpty == true;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seguimiento del pedido',
              style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            Text(widget.numeroPedido, style: GoogleFonts.inter(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _actualizando ? null : _refrescar,
            icon: _actualizando
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.local_shipping_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estado,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimaryFixed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Desliza hacia abajo para consultar el estado más reciente.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onPrimaryFixedVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              icon: Icons.person_rounded,
              title: asignado ? _repartidorNombre! : 'Personal por asignar',
              subtitle: asignado
                  ? 'Responsable de la recolección o entrega'
                  : 'La lavandería asignará a una persona pronto.',
              trailing: asignado
                  ? IconButton.filled(
                      tooltip: 'Llamar',
                      onPressed: _llamarRepartidor,
                      icon: const Icon(Icons.phone_rounded),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            _InfoCard(
              icon: Icons.location_on_rounded,
              title: 'Dirección del servicio',
              subtitle: _direccion,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'La app todavía no recibe ubicación GPS en tiempo real. Por eso mostramos el estado confirmado y el contacto real, sin simular un mapa.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
