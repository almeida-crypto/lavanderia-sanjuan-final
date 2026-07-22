import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/pedido.dart';
import '../../../services/pedido_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import '../servicios/servicios_screen.dart';

class SeguimientoEnVivoScreen extends StatefulWidget {
  const SeguimientoEnVivoScreen({
    super.key,
    required this.pedidoId,
    required this.numeroPedido,
    this.repartidorNombre,
  });

  final String pedidoId;
  final String numeroPedido;
  final String? repartidorNombre;

  @override
  State<SeguimientoEnVivoScreen> createState() => _SeguimientoEnVivoScreenState();
}

class _SeguimientoEnVivoScreenState extends State<SeguimientoEnVivoScreen> {
  final _pedidoService = PedidoService();
  late String? _repartidorNombre = widget.repartidorNombre;

  Future<void> _refrescar() async {
    try {
      final actualizado = await _pedidoService.obtenerPedido(widget.pedidoId);
      final pedido = Pedido.fromJson(actualizado);
      if (mounted) setState(() => _repartidorNombre = pedido.repartidorNombre);
    } catch (_) {
      // Sin conexión: se queda mostrando lo último que sí se cargó.
    }
  }

  Future<void> _copiarContacto(BuildContext context, String numero) async {
    await Clipboard.setData(ClipboardData(text: numero));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Número $numero copiado')),
    );
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seguimiento en Vivo',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              widget.numeroPedido,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refrescar,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  const Positioned.fill(child: _MapaSimulado()),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: _OverlayCard(
                      repartidorNombre: _repartidorNombre,
                      onSoporte: () => _copiarContacto(context, '+52 555 010 1010'),
                    ),
                  ),
                ],
              ),
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

class _MapaSimulado extends StatefulWidget {
  const _MapaSimulado();

  @override
  State<_MapaSimulado> createState() => _MapaSimuladoState();
}

class _MapaSimuladoState extends State<_MapaSimulado> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _RutaPainter()),
          const Align(
            alignment: Alignment(0.55, -0.6),
            child: _MarcadorPlanta(),
          ),
          Align(
            alignment: const Alignment(-0.6, 0.6),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => _MarcadorHogar(progreso: _pulseController.value),
            ),
          ),
          const Align(
            alignment: Alignment(0.1, -0.05),
            child: _MarcadorVan(),
          ),
        ],
      ),
    );
  }
}

class _RutaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.4,
        size.width * 0.8,
        size.height * 0.2,
      );

    final paint = Paint()
      ..color = AppColors.primaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final dashed = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        const dashLength = 10.0;
        const gapLength = 8.0;
        final next = math.min(distance + dashLength, metric.length);
        dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next + gapLength;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MarcadorPlanta extends StatelessWidget {
  const _MarcadorPlanta();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
      ),
      child: const Icon(Icons.local_laundry_service_rounded, color: AppColors.primary, size: 18),
    );
  }
}

class _MarcadorHogar extends StatelessWidget {
  const _MarcadorHogar({required this.progreso});

  final double progreso;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: (1 - progreso).clamp(0.0, 1.0).toDouble(),
            child: Container(
              width: 24 + progreso * 24,
              height: 24 + progreso * 24,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarcadorVan extends StatelessWidget {
  const _MarcadorVan();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10)],
      ),
      child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({required this.repartidorNombre, required this.onSoporte});

  final String? repartidorNombre;
  final VoidCallback onSoporte;

  @override
  Widget build(BuildContext context) {
    final asignado = repartidorNombre != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryFixed,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asignado ? 'Repartidor en camino' : 'Buscando repartidor disponible',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimaryFixed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No contamos aún con ubicación GPS en tiempo real; esta pantalla refleja el estado real de tu pedido.',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                        repartidorNombre ?? 'Repartidor por asignar',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        asignado ? 'Asignado a tu pedido' : 'El admin aún no asigna repartidor',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSoporte,
                icon: const Icon(Icons.support_agent_rounded, size: 20),
                label: Text(
                  'Contactar Soporte',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
