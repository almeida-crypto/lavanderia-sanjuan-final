import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/direccion.dart';
import '../../../providers/direcciones_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import '../servicios/servicios_screen.dart';
import 'eliminar_direccion_dialog.dart';
import 'formulario_direccion_screen.dart';
import 'mi_perfil_screen.dart';

class MisDireccionesScreen extends StatelessWidget {
  const MisDireccionesScreen({super.key});

  Future<void> _eliminar(BuildContext context, int index) async {
    final provider = context.read<DireccionesProvider>();
    final confirmado = await mostrarConfirmacionEliminarDireccion(
      context,
      provider.direcciones[index],
    );
    if (confirmado) {
      try {
        await provider.eliminar(index);
      } catch (_) {
        if (context.mounted) _error(context, 'No se pudo eliminar la dirección');
      }
    }
  }

  Future<void> _agregarDireccion(BuildContext context) async {
    final nueva = await Navigator.of(context).push<Direccion>(
      MaterialPageRoute(builder: (_) => const FormularioDireccionScreen()),
    );
    if (nueva != null && context.mounted) {
      try {
        await context.read<DireccionesProvider>().agregar(nueva);
      } catch (_) {
        if (context.mounted) _error(context, 'No se pudo guardar la dirección');
      }
    }
  }

  Future<void> _editar(BuildContext context, int index) async {
    final provider = context.read<DireccionesProvider>();
    final editada = await Navigator.of(context).push<Direccion>(
      MaterialPageRoute(
        builder: (_) => FormularioDireccionScreen(direccionExistente: provider.direcciones[index]),
      ),
    );
    if (editada != null && context.mounted) {
      try {
        await provider.actualizar(index, editada);
      } catch (_) {
        if (context.mounted) _error(context, 'No se pudo actualizar la dirección');
      }
    }
  }

  void _error(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
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
      case AppBottomTab.profile:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MiPerfilScreen()),
        );
      case AppBottomTab.orders:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MisPedidosScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DireccionesProvider>();
    final direcciones = provider.direcciones;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Mis Direcciones',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _agregarDireccion(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MapaCoberturaPlaceholder(),
              const SizedBox(height: 16),
              if (provider.isLoading) const LinearProgressIndicator(),
              if (provider.error != null && direcciones.isEmpty) ...[
                Text(provider.error!, style: const TextStyle(color: AppColors.error)),
                TextButton(onPressed: provider.cargar, child: const Text('Reintentar')),
              ],
              for (var i = 0; i < direcciones.length; i++) ...[
                _DireccionCard(
                  direccion: direcciones[i],
                  onEditar: () => _editar(context, i),
                  onEliminar: () => _eliminar(context, i),
                  onMarcarPredeterminada: () async {
                    try {
                      await context.read<DireccionesProvider>().marcarPredeterminada(i);
                    } catch (_) {
                      if (context.mounted) _error(context, 'No se pudo cambiar la dirección principal');
                    }
                  },
                ),
                if (i != direcciones.length - 1) const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _agregarDireccion(context),
                icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                label: Text(
                  'Añadir nueva dirección',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppBottomTab.profile,
        onTabSelected: (tab) => _onTabSelected(context, tab),
      ),
    );
  }
}

class _MapaCoberturaPlaceholder extends StatelessWidget {
  const _MapaCoberturaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceContainer, AppColors.primaryFixed],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.map_rounded,
              size: 72,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Área de servicio',
                    style: GoogleFonts.inter(
                      fontSize: 12,
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
    );
  }
}

class _DireccionCard extends StatelessWidget {
  const _DireccionCard({
    required this.direccion,
    required this.onEditar,
    required this.onEliminar,
    required this.onMarcarPredeterminada,
  });

  final Direccion direccion;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onMarcarPredeterminada;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: direccion.predeterminada
                      ? AppColors.primaryFixed
                      : AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  direccion.icon,
                  color: direccion.predeterminada ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            direccion.titulo,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        if (direccion.predeterminada) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'PREDETERMINADA',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final linea in direccion.lineas)
                      Text(
                        linea,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                      ),
                    if (direccion.telefono != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.call_outlined, size: 16, color: AppColors.outline),
                          const SizedBox(width: 6),
                          Text(
                            direccion.telefono!,
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.outline),
                          ),
                        ],
                      ),
                    ],
                    if (direccion.nota != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        direccion.nota!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!direccion.predeterminada)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant),
                  onSelected: (valor) {
                    if (valor == 'predeterminada') onMarcarPredeterminada();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'predeterminada',
                      child: Text('Marcar como predeterminada'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainer,
                    foregroundColor: AppColors.primary,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainer,
                    foregroundColor: AppColors.error,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
