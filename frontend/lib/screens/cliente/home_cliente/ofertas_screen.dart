import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/promocion.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_image.dart';
import 'detalle_oferta_screen.dart';

/// Lista completa de ofertas vigentes. Antes de esta pantalla, Inicio solo
/// mostraba UNA promoción (la primera que encontraba), aunque el admin
/// tuviera 2 o 3 activas al mismo tiempo; aquí sí se ven todas.
class OfertasScreen extends StatelessWidget {
  const OfertasScreen({super.key, required this.promociones});

  final List<Promocion> promociones;

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
        title: Text(
          'Ofertas Vigentes',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: promociones.length,
          itemBuilder: (context, index) {
            final promocion = promociones[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _OfertaCard(
                promocion: promocion,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DetalleOfertaScreen(promocion: promocion)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OfertaCard extends StatelessWidget {
  const _OfertaCard({required this.promocion, required this.onTap});

  final Promocion promocion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 68,
                height: 68,
                child: AppImage(
                  url: promocion.imagenUrl,
                  fallbackAsset: 'assets/images/promocion_default.png',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promocion.titulo,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Código: ${promocion.codigo}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  if (promocion.condicionesTexto != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      promocion.condicionesTexto!,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
