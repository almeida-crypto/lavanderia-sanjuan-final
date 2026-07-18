import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/tarjeta.dart';
import '../../../providers/metodos_pago_provider.dart';
import '../../../utils/app_colors.dart';
import 'agregar_tarjeta_screen.dart';

class SeleccionarMetodoPagoScreen extends StatefulWidget {
  const SeleccionarMetodoPagoScreen({
    super.key,
    required this.seleccionActual,
    required this.esEfectivoInicial,
  });

  final TarjetaGuardada? seleccionActual;
  final bool esEfectivoInicial;

  @override
  State<SeleccionarMetodoPagoScreen> createState() =>
      _SeleccionarMetodoPagoScreenState();
}

class _SeleccionarMetodoPagoScreenState
    extends State<SeleccionarMetodoPagoScreen> {
  late TarjetaGuardada? _seleccionada = widget.seleccionActual;
  late bool _esEfectivo = widget.esEfectivoInicial;

  Future<void> _agregarTarjeta() async {
    final nueva = await Navigator.of(context).push<TarjetaGuardada>(
      MaterialPageRoute(builder: (_) => const AgregarTarjetaScreen()),
    );
    if (nueva != null && mounted) {
      try {
        final guardada = await context.read<MetodosPagoProvider>().agregar(nueva);
        if (mounted) {
          setState(() {
            _seleccionada = guardada;
            _esEfectivo = false;
          });
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar la tarjeta')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarjetas = context.watch<MetodosPagoProvider>().tarjetas;

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
          'Método de Pago',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
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
              Text(
                'Método de Pago',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() {
                  _esEfectivo = true;
                  _seleccionada = null;
                }),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _esEfectivo
                        ? AppColors.surfaceContainerLow
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _esEfectivo ? AppColors.primary : AppColors.surfaceVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Efectivo contra entrega',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'Paga al repartidor al recibir tus prendas',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _esEfectivo
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: _esEfectivo
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Mis Tarjetas Guardadas',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < tarjetas.length; i++) ...[
                _TarjetaOpcion(
                  tarjeta: tarjetas[i],
                  seleccionada: tarjetas[i] == _seleccionada,
                  onTap: () => setState(() {
                    _seleccionada = tarjetas[i];
                    _esEfectivo = false;
                  }),
                ),
                if (i != tarjetas.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              InkWell(
                onTap: _agregarTarjeta,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_card_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Añadir Nueva Tarjeta',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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
              onPressed: (_esEfectivo == false && _seleccionada == null)
                  ? null
                  : () {
                      if (_esEfectivo) {
                        Navigator.of(context).pop('efectivo');
                      } else {
                        Navigator.of(context).pop(_seleccionada);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Confirmar Método de Pago',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaOpcion extends StatelessWidget {
  const _TarjetaOpcion({
    required this.tarjeta,
    required this.seleccionada,
    required this.onTap,
  });

  final TarjetaGuardada tarjeta;
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
          color: seleccionada
              ? AppColors.surfaceContainerLow
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionada ? AppColors.primary : AppColors.surfaceVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                tarjeta.marca == MarcaTarjeta.mastercard ? 'MC' : 'VISA',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tarjeta.marca == MarcaTarjeta.mastercard ? 'Mastercard' : 'Visa'} **** ${tarjeta.ultimosDigitos}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Vence ${tarjeta.expira}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              seleccionada
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: seleccionada
                  ? AppColors.primary
                  : AppColors.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
