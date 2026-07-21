import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/promocion.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_image.dart';
import 'add_promocion_screen.dart';

class PromocionesScreen extends StatefulWidget {
  const PromocionesScreen({super.key});

  @override
  State<PromocionesScreen> createState() => _PromocionesScreenState();
}

class _PromocionesScreenState extends State<PromocionesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminProvider>().cargarPromociones();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final promociones = provider.promociones;

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
          'Promociones',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddPromocionScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text('Nueva', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: provider.isLoadingPromociones && promociones.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : promociones.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aún no hay promociones. Crea una para que el cliente la vea en Inicio.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<AdminProvider>().cargarPromociones(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: promociones.length,
                      itemBuilder: (context, index) => _PromocionCard(promocion: promociones[index]),
                    ),
                  ),
      ),
    );
  }
}

class _PromocionCard extends StatelessWidget {
  const _PromocionCard({required this.promocion});

  final Promocion promocion;

  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _fecha(DateTime fecha) => '${fecha.day} ${_meses[fecha.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final vigente = promocion.vigente;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: promocion.activa ? AppColors.surfaceVariant : AppColors.surfaceVariant.withValues(alpha: 0.5)),
      ),
      color: promocion.activa ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow.withValues(alpha: 0.7),
      child: Opacity(
        opacity: promocion.activa ? 1.0 : 0.7,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: AppImage(
                    url: promocion.imagenUrl,
                    fallbackAsset: 'assets/images/promocion_default.png',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      promocion.titulo,
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        promocion.activa ? 'Activa' : 'Inactiva',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: promocion.activa,
                        activeThumbColor: AppColors.primary,
                        onChanged: (_) async {
                          try {
                            await context.read<AdminProvider>().togglePromocionActiva(promocion.id);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No se pudo actualizar la promoción')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                promocion.descripcion,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    icon: Icons.sell_outlined,
                    texto: '${promocion.descuentoPorcentaje.toStringAsFixed(0)}% · ${promocion.codigo}',
                  ),
                  if (promocion.condicionesTexto != null)
                    _Chip(
                      icon: Icons.rule_outlined,
                      texto: promocion.condicionesTexto!,
                    ),
                  _Chip(
                    icon: Icons.local_laundry_service_outlined,
                    texto: (promocion.servicioAplicable?.isNotEmpty ?? false)
                        ? promocion.servicioAplicable!
                        : 'Todos los servicios',
                  ),
                  _Chip(
                    icon: Icons.event_outlined,
                    texto: promocion.fechaFin == null
                        ? 'Desde ${_fecha(promocion.fechaInicio)}'
                        : '${_fecha(promocion.fechaInicio)} – ${_fecha(promocion.fechaFin!)}',
                  ),
                  _Chip(
                    icon: vigente ? Icons.check_circle_outline : Icons.info_outline,
                    texto: vigente ? 'Vigente ahora' : 'Fuera de vigencia',
                    color: vigente ? AppColors.primary : AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.surfaceVariant),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddPromocionScreen(promocion: promocion)),
                  ),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('Editar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.texto, this.color});

  final IconData icon;
  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 4),
          Text(texto, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: effectiveColor)),
        ],
      ),
    );
  }
}
