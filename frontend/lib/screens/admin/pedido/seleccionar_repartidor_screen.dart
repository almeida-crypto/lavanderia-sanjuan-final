import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido_admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';

class _Repartidor {
  const _Repartidor({required this.nombre, required this.vehiculo, required this.rating, required this.initials});

  final String nombre;
  final String vehiculo;
  final String rating;
  final String initials;
}

const _repartidoresDisponibles = [
  _Repartidor(nombre: 'Carlos Mendoza', vehiculo: 'FreshVan #042', rating: '4.9 (124 viajes)', initials: 'CM'),
  _Repartidor(nombre: 'Laura Gómez', vehiculo: 'FreshBike #12', rating: '4.7 (89 viajes)', initials: 'LG'),
  _Repartidor(nombre: 'Roberto Díaz', vehiculo: 'FreshVan #018', rating: '5.0 (312 viajes)', initials: 'RD'),
];

class SeleccionarRepartidorScreen extends StatefulWidget {
  const SeleccionarRepartidorScreen({super.key, required this.pedido});

  final PedidoAdmin pedido;

  @override
  State<SeleccionarRepartidorScreen> createState() => _SeleccionarRepartidorScreenState();
}

class _SeleccionarRepartidorScreenState extends State<SeleccionarRepartidorScreen> {
  late String? _seleccionado = widget.pedido.repartidorNombre;
  bool _isSaving = false;

  Future<void> _confirmar(BuildContext context) async {
    final repartidor = _seleccionado;
    if (repartidor == null) return;

    setState(() => _isSaving = true);
    try {
      await context.read<AdminProvider>().assignRepartidor(widget.pedido.id, repartidor);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Repartidor $repartidor asignado al pedido.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo asignar el repartidor, intenta de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Asignar Repartidor',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _repartidoresDisponibles.length,
                itemBuilder: (context, index) {
                  final repartidor = _repartidoresDisponibles[index];
                  final isSelected = _seleccionado == repartidor.nombre;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    color: isSelected
                        ? AppColors.primaryFixed.withValues(alpha: 0.3)
                        : AppColors.surfaceContainerLowest,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _seleccionado = repartidor.nombre),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.secondaryContainer,
                              child: Text(
                                repartidor.initials,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    repartidor.nombre,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.local_shipping_outlined,
                                          color: AppColors.onSurfaceVariant, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        repartidor.vehiculo,
                                        style: GoogleFonts.inter(
                                            fontSize: 12, color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        repartidor.rating,
                                        style: GoogleFonts.inter(
                                            fontSize: 12, color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.outline,
                                  width: 2,
                                ),
                                color: isSelected ? AppColors.primary : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_seleccionado == null || _isSaving) ? null : () => _confirmar(context),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar Selección'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
