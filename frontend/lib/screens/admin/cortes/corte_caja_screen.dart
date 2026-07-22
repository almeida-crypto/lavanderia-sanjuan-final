import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../models/corte_caja.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/corte_pdf_generator.dart';
import '../../../utils/app_colors.dart';

/// Corte de caja: cuánto entró, cuántos pedidos se recibieron/entregaron/
/// cancelaron y cómo se pagó cada uno, para un día en concreto. Se calcula
/// con los pedidos que ya están cargados en el panel, y se puede descargar
/// como PDF para imprimir o archivar.
class CorteCajaScreen extends StatefulWidget {
  const CorteCajaScreen({super.key});

  @override
  State<CorteCajaScreen> createState() => _CorteCajaScreenState();
}

class _CorteCajaScreenState extends State<CorteCajaScreen> {
  DateTime _fecha = DateTime.now();
  bool _generandoPdf = false;

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  String _fechaTexto(DateTime fecha) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final hoy = DateTime.now();
    final esHoy = fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
    final texto = '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
    return esHoy ? 'Hoy · $texto' : texto;
  }

  Future<void> _descargarPdf(CorteCaja corte) async {
    setState(() => _generandoPdf = true);
    try {
      final bytes = await generarCortePdf(corte);
      final nombre =
          'corte_caja_${corte.fecha.year}-${corte.fecha.month.toString().padLeft(2, '0')}-${corte.fecha.day.toString().padLeft(2, '0')}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: nombre);
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final corte = CorteCaja.calcular(admin.pedidos, _fecha);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Corte de Caja',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: admin.cargarPedidos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _elegirFecha,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fechaTexto(_fecha),
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                      ),
                      const Icon(Icons.expand_more_rounded, color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _TarjetaResumen(
                    titulo: 'Ingresos del día',
                    valor: '\$${corte.ingresosTotales.toStringAsFixed(2)}',
                    icono: Icons.payments_rounded,
                    color: AppColors.primary,
                    destacada: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TarjetaResumen(
                    titulo: 'Recibidos',
                    valor: '${corte.pedidosRecibidos}',
                    icono: Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _TarjetaResumen(
                    titulo: 'Entregados',
                    valor: '${corte.pedidosEntregados}',
                    icono: Icons.task_alt_rounded,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TarjetaResumen(
                    titulo: 'En proceso',
                    valor: '${corte.pedidosEnProceso}',
                    icono: Icons.sync_rounded,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  _TarjetaResumen(
                    titulo: 'Cancelados',
                    valor: '${corte.pedidosCancelados}',
                    icono: Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Desglose por método de pago',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 12),
              if (corte.porMetodoPago.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Text(
                    'Sin pagos registrados este día.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      for (final entrada in corte.porMetodoPago.entries) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entrada.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                                ),
                              ),
                              Text(
                                '\$${entrada.value.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        if (entrada.key != corte.porMetodoPago.keys.last)
                          const Divider(color: AppColors.surfaceVariant, height: 1),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generandoPdf ? null : () => _descargarPdf(corte),
                  icon: _generandoPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    _generandoPdf ? 'Generando PDF...' : 'Descargar PDF',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    this.destacada = false,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: destacada ? color.withValues(alpha: 0.08) : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: destacada ? color.withValues(alpha: 0.3) : AppColors.surfaceVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icono, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: destacada ? 24 : 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
