import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/pedido_ops_service.dart';
import '../../../utils/app_colors.dart';

class _Criterio {
  const _Criterio({required this.icon, required this.etiqueta});

  final IconData icon;
  final String etiqueta;
}

const _criterios = [
  _Criterio(icon: Icons.schedule_rounded, etiqueta: 'Puntualidad'),
  _Criterio(icon: Icons.local_laundry_service_rounded, etiqueta: 'Calidad de Lavado'),
  _Criterio(icon: Icons.local_shipping_rounded, etiqueta: 'Trato del Repartidor'),
];

class CalificarServicioScreen extends StatefulWidget {
  const CalificarServicioScreen({super.key, required this.pedidoId, required this.numeroPedido});

  final String pedidoId;
  final String numeroPedido;

  @override
  State<CalificarServicioScreen> createState() => _CalificarServicioScreenState();
}

class _CalificarServicioScreenState extends State<CalificarServicioScreen> {
  final _pedidoOpsService = PedidoOpsService();
  int _calificacionGeneral = 0;
  final _calificacionesDetalle = List<int>.filled(_criterios.length, 0);
  final _resenaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _resenaController.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    setState(() => _isLoading = true);
    try {
      await _pedidoOpsService.calificarPedido(
        widget.pedidoId,
        calificacionGeneral: _calificacionGeneral,
        resena: _resenaController.text.trim(),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tu calificación!')),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar la calificación')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          icon: const Icon(Icons.close_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Calificar Servicio',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeroBanner(),
              const SizedBox(height: 24),
              Text(
                '¡Pedido Entregado! ¿Cómo estuvo todo?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu opinión nos ayuda a mantener nuestro servicio impecable.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.secondary),
              ),
              const SizedBox(height: 24),
              _EstrellasSelector(
                calificacion: _calificacionGeneral,
                tamano: 40,
                onChanged: (valor) => setState(() => _calificacionGeneral = valor),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceDim),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Califica los detalles',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < _criterios.length; i++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(_criterios[i].icon, size: 20, color: AppColors.secondary),
                              const SizedBox(width: 8),
                              Text(
                                _criterios[i].etiqueta,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          _EstrellasSelector(
                            calificacion: _calificacionesDetalle[i],
                            tamano: 22,
                            onChanged: (valor) => setState(() => _calificacionesDetalle[i] = valor),
                          ),
                        ],
                      ),
                      if (i != _criterios.length - 1) const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _resenaController,
                minLines: 4,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  hintText: 'Escribe tu reseña (opcional)',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.secondary),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_calificacionGeneral == 0 || _isLoading) ? null : _enviarCalificacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.outlineVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Enviar Calificación',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.send_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 176,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryFixed, AppColors.surfaceContainerHigh],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_laundry_service_rounded,
          size: 72,
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _EstrellasSelector extends StatelessWidget {
  const _EstrellasSelector({
    required this.calificacion,
    required this.onChanged,
    this.tamano = 28,
  });

  final int calificacion;
  final double tamano;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final valor = index + 1;
        final lleno = valor <= calificacion;
        return InkWell(
          onTap: () => onChanged(valor),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              lleno ? Icons.star_rounded : Icons.star_outline_rounded,
              size: tamano,
              color: lleno ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
        );
      }),
    );
  }
}
