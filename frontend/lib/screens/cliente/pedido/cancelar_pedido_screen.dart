import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/pedido_ops_service.dart';
import '../../../utils/app_colors.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';

const _razones = [
  'Pedido por error',
  'Muy costoso',
  'Encontré un mejor precio',
  'El repartidor tarda demasiado',
  'Otro',
];

class CancelarPedidoScreen extends StatefulWidget {
  const CancelarPedidoScreen({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<CancelarPedidoScreen> createState() => _CancelarPedidoScreenState();
}

class _CancelarPedidoScreenState extends State<CancelarPedidoScreen> {
  final _pedidoOpsService = PedidoOpsService();
  String _razonSeleccionada = _razones.last;
  final _comentariosController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _comentariosController.dispose();
    super.dispose();
  }

  Future<void> _confirmarCancelacion() async {
    setState(() => _isLoading = true);
    try {
      await _pedidoOpsService.cancelarPedido(
        widget.pedidoId,
        razon: _razonSeleccionada,
        comentarios: _comentariosController.text.trim(),
      );
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MisPedidosScreen()),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado correctamente')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cancelar el pedido')),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Cancelar Pedido',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AvisoCargo(),
              const SizedBox(height: 32),
              Text(
                '¿Por qué deseas cancelar?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _razones.length; i++) ...[
                _RazonTile(
                  texto: _razones[i],
                  seleccionada: _razones[i] == _razonSeleccionada,
                  onTap: () => setState(() => _razonSeleccionada = _razones[i]),
                ),
                if (i != _razones.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 32),
              Text(
                'Comentarios adicionales (opcional)',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _comentariosController,
                minLines: 3,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  hintText: 'Cuéntanos más sobre por qué cancelas...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.outlineVariant),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmarCancelacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Confirmar Cancelación',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Mantener Pedido',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
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

class _AvisoCargo extends StatelessWidget {
  const _AvisoCargo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.onErrorContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Las cancelaciones pueden generar un cargo',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Si el repartidor ya va en camino a tu domicilio, se podría aplicar un '
                  'pequeño cargo por cancelación para cubrir su tiempo de traslado.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onErrorContainer.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RazonTile extends StatelessWidget {
  const _RazonTile({required this.texto, required this.seleccionada, required this.onTap});

  final String texto;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionada ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              texto,
              style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurface),
            ),
            Icon(
              seleccionada ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: seleccionada ? AppColors.primary : AppColors.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
