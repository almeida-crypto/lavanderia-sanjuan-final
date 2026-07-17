import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/pedido.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import '../servicios/servicios_screen.dart';
import 'cancelar_pedido_screen.dart';
import 'reportar_problema_screen.dart';
import 'seguimiento_en_vivo_screen.dart';

enum _PasoEstado { completado, actual, pendiente }

class _PasoPedido {
  const _PasoPedido({required this.titulo, required this.descripcion, required this.estado});

  final String titulo;
  final String descripcion;
  final _PasoEstado estado;
}

List<_PasoPedido> _pasosPara(Pedido pedido) {
  final confirmado = _PasoPedido(
    titulo: 'Pedido Confirmado',
    descripcion: 'Programado para ${pedido.franjaHoraria.isEmpty ? pedido.fechaFormateada : '${pedido.franjaHoraria}, ${pedido.fechaFormateada}'}.',
    estado: _PasoEstado.completado,
  );

  final enProceso = _PasoPedido(
    titulo: 'En Proceso',
    descripcion: 'Tu pedido está siendo atendido en planta.',
    estado: pedido.estado == EstadoPedido.entregado ? _PasoEstado.completado : _PasoEstado.actual,
  );

  final entregado = _PasoPedido(
    titulo: 'Entregado',
    descripcion: 'Tu ropa fue entregada.',
    estado: pedido.estado == EstadoPedido.entregado ? _PasoEstado.completado : _PasoEstado.pendiente,
  );

  return [confirmado, enProceso, entregado];
}

class PedidoScreen extends StatelessWidget {
  const PedidoScreen({super.key, required this.pedido});

  final Pedido pedido;

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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MisPedidosScreen()),
        );
      case AppBottomTab.profile:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MiPerfilScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final necesitaAtencion = pedido.estado == EstadoPedido.atencion;
    final activo = pedido.estado == EstadoPedido.enProceso || necesitaAtencion;
    final cancelado = pedido.estado == EstadoPedido.cancelado;
    final puedeReportar = !cancelado;
    final puedeCancelar = activo;
    final (chipColor, chipTexto) = switch (pedido.estado) {
      EstadoPedido.enProceso => (AppColors.primary, 'En Proceso'),
      EstadoPedido.atencion => (AppColors.error, 'Atención requerida'),
      EstadoPedido.entregado => (AppColors.primary, 'Entregado'),
      EstadoPedido.cancelado => (AppColors.error, 'Cancelado'),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Pedido ${pedido.numero}',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    chipTexto,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: chipColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cancelado)
                _PedidoCanceladoCard(pedido: pedido)
              else ...[
                if (necesitaAtencion) ...[
                  const _AtencionBanner(),
                  const SizedBox(height: 16),
                ],
                _EstimacionCard(
                  pedido: pedido,
                  onVerMapa: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SeguimientoEnVivoScreen(
                        numeroPedido: pedido.numero,
                        repartidorNombre: pedido.repartidorNombre,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _TimelineCard(pedido: pedido),
                if (activo && pedido.repartidorNombre != null) ...[
                  const SizedBox(height: 16),
                  _RepartidorCard(
                    nombre: pedido.repartidorNombre!,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SeguimientoEnVivoScreen(
                          numeroPedido: pedido.numero,
                          repartidorNombre: pedido.repartidorNombre,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              if (puedeReportar || puedeCancelar) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (puedeReportar)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ReportarProblemaScreen(pedido: pedido)),
                          ),
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: Text(
                            'Reportar un Problema',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                        ),
                      ),
                    if (puedeCancelar)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CancelarPedidoScreen(pedidoId: pedido.id)),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: Text(
                            'Cancelar Pedido',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ],
            ],
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

class _PedidoCanceladoCard extends StatelessWidget {
  const _PedidoCanceladoCard({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.error, size: 32),
          const SizedBox(height: 12),
          Text(
            'Este pedido fue cancelado',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '${pedido.servicio} · ${pedido.fechaFormateada}',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AtencionBanner extends StatelessWidget {
  const _AtencionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu pedido necesita atención',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nuestro equipo está revisando algo en tu pedido y se pondrá en contacto contigo.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimacionCard extends StatelessWidget {
  const _EstimacionCard({required this.pedido, required this.onVerMapa});

  final Pedido pedido;
  final VoidCallback onVerMapa;

  @override
  Widget build(BuildContext context) {
    final entregado = pedido.estado == EstadoPedido.entregado;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entregado ? 'Entrega realizada' : 'Ventana de recolección/entrega',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pedido.franjaHoraria.isEmpty
                        ? pedido.fechaFormateada
                        : '${pedido.franjaHoraria} · ${pedido.fechaFormateada}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onVerMapa,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: entregado ? 1.0 : 0.5,
              minHeight: 8,
              backgroundColor: AppColors.secondaryContainer,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Confirmado', style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary)),
              Text('En proceso', style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary)),
              Text('Entregado', style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final pasos = _pasosPara(pedido);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado del Pedido',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < pasos.length; i++)
            _TimelineStep(paso: pasos[i], isLast: i == pasos.length - 1),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.paso, required this.isLast});

  final _PasoPedido paso;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final atenuado = paso.estado == _PasoEstado.pendiente;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _buildDot(),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.secondaryContainer),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        paso.titulo,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: paso.estado == _PasoEstado.actual
                              ? AppColors.primary
                              : atenuado
                              ? AppColors.secondary
                              : AppColors.onSurface,
                        ),
                      ),
                      if (paso.estado == _PasoEstado.actual)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Actual',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      paso.descripcion,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: atenuado ? AppColors.secondary : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    switch (paso.estado) {
      case _PasoEstado.completado:
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
        );
      case _PasoEstado.actual:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
          ),
        );
      case _PasoEstado.pendiente:
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
        );
    }
  }
}

class _RepartidorCard extends StatelessWidget {
  const _RepartidorCard({required this.nombre, required this.onTap});

  final String nombre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu Repartidor',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.onSurfaceVariant, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Repartidor asignado a tu pedido',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.call_rounded, size: 20),
                  label: const Text('Llamar'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                    foregroundColor: AppColors.primary,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.support_agent_rounded, size: 20),
                  label: const Text('Soporte'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                    foregroundColor: AppColors.primary,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
