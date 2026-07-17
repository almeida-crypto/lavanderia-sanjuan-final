import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/pedido.dart';
import '../../../services/pedido_ops_service.dart';
import '../../../utils/app_colors.dart';

class _TipoProblema {
  const _TipoProblema({required this.icon, required this.etiqueta});

  final IconData icon;
  final String etiqueta;
}

const _tiposProblema = [
  _TipoProblema(icon: Icons.checkroom_rounded, etiqueta: 'Prenda Dañada'),
  _TipoProblema(icon: Icons.search_off_rounded, etiqueta: 'Falta una Prenda'),
  _TipoProblema(icon: Icons.schedule_rounded, etiqueta: 'Retraso en Entrega'),
  _TipoProblema(icon: Icons.water_drop_rounded, etiqueta: 'Calidad de Lavado'),
  _TipoProblema(icon: Icons.more_horiz_rounded, etiqueta: 'Otro problema'),
];

class ReportarProblemaScreen extends StatefulWidget {
  const ReportarProblemaScreen({super.key, required this.pedido});

  final Pedido pedido;

  @override
  State<ReportarProblemaScreen> createState() => _ReportarProblemaScreenState();
}

class _ReportarProblemaScreenState extends State<ReportarProblemaScreen> {
  final _pedidoOpsService = PedidoOpsService();
  String? _tipoSeleccionado;
  final _detallesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _detallesController.dispose();
    super.dispose();
  }

  Future<void> _enviarReporte() async {
    setState(() => _isLoading = true);
    try {
      await _pedidoOpsService.reportarProblema(
        widget.pedido.id,
        tipo: _tipoSeleccionado ?? 'Otro problema',
        detalles: _detallesController.text.trim(),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado. Nuestro equipo te contactará pronto.')),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el reporte')),
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Reportar un Problema',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrdenActualCard(
                numeroPedido: widget.pedido.numero,
                onVerDetalles: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 32),
              Text(
                '¿Qué salió mal?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tiposProblema.length - 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final tipo = _tiposProblema[index];
                  return _TipoProblemaCard(
                    tipo: tipo,
                    seleccionado: _tipoSeleccionado == tipo.etiqueta,
                    onTap: () => setState(() => _tipoSeleccionado = tipo.etiqueta),
                  );
                },
              ),
              const SizedBox(height: 12),
              _TipoProblemaCard(
                tipo: _tiposProblema.last,
                seleccionado: _tipoSeleccionado == _tiposProblema.last.etiqueta,
                onTap: () => setState(() => _tipoSeleccionado = _tiposProblema.last.etiqueta),
                horizontal: true,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Detalles',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Opcional',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detallesController,
                minLines: 4,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  hintText: 'Cuéntanos más sobre lo sucedido para poder ayudarte mejor...',
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
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_tipoSeleccionado == null || _isLoading) ? null : _enviarReporte,
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
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Enviar Reporte',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdenActualCard extends StatelessWidget {
  const _OrdenActualCard({required this.numeroPedido, required this.onVerDetalles});

  final String numeroPedido;
  final VoidCallback onVerDetalles;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDEN ACTUAL',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  numeroPedido,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onVerDetalles,
            child: Text(
              'Ver Detalles',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipoProblemaCard extends StatelessWidget {
  const _TipoProblemaCard({
    required this.tipo,
    required this.seleccionado,
    required this.onTap,
    this.horizontal = false,
  });

  final _TipoProblema tipo;
  final bool seleccionado;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final icono = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.primary : AppColors.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(tipo.icon, color: seleccionado ? Colors.white : AppColors.primary),
    );
    final etiqueta = Text(
      tipo.etiqueta,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.4),
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: horizontal
            ? Row(children: [icono, const SizedBox(width: 12), Expanded(child: etiqueta)])
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [icono, const SizedBox(height: 8), etiqueta],
              ),
      ),
    );
  }
}
