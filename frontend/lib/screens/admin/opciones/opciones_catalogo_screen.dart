import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/opcion_catalogo.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';
import 'add_opcion_screen.dart';

/// Catálogo global de opciones (ej. "Doblado en Gancho") reutilizables
/// entre servicios: se editan aquí una sola vez y cada servicio (en su
/// propia pantalla de edición) elige cuáles ofrece y a qué precio.
class OpcionesCatalogoScreen extends StatefulWidget {
  const OpcionesCatalogoScreen({super.key});

  @override
  State<OpcionesCatalogoScreen> createState() => _OpcionesCatalogoScreenState();
}

class _OpcionesCatalogoScreenState extends State<OpcionesCatalogoScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminProvider>().cargarOpcionesCatalogo();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final opciones = provider.opcionesCatalogo;

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
          'Opciones',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddOpcionScreen()),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Se definen una vez aquí y luego se activan por servicio (con su propio precio) '
                'desde "Editar Servicio".',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: provider.isLoadingOpcionesCatalogo && opciones.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : opciones.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Aún no hay opciones. Crea, por ejemplo, "Doblado en Gancho".',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => context.read<AdminProvider>().cargarOpcionesCatalogo(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: opciones.length,
                            itemBuilder: (context, index) => _OpcionCard(opcion: opciones[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionCard extends StatelessWidget {
  const _OpcionCard({required this.opcion});

  final OpcionCatalogo opcion;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: opcion.activa ? AppColors.surfaceVariant : AppColors.surfaceVariant.withValues(alpha: 0.5)),
      ),
      color: opcion.activa ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opcion.nombre,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  ),
                  if (opcion.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      opcion.descripcion,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddOpcionScreen(opcion: opcion)),
              ),
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            ),
            Switch.adaptive(
              value: opcion.activa,
              activeThumbColor: AppColors.primary,
              onChanged: (_) async {
                try {
                  await context.read<AdminProvider>().toggleOpcionCatalogoActiva(opcion.id);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo actualizar la opción')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
