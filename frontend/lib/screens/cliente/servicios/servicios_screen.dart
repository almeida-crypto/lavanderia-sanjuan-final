import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/servicio_display.dart';
import '../../../models/servicio_lavanderia.dart';
import '../../../providers/servicios_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import 'edredones_screen.dart';
import 'lavado_kilo_screen.dart';
import 'planchado_screen.dart';
import 'tintoreria_screen.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<ServiciosProvider>().cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onServicioTap(BuildContext context, TipoServicio tipo) {
    switch (tipo) {
      case TipoServicio.tintoreria:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TintoreriaScreen()),
        );
      case TipoServicio.planchado:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlanchadoScreen()),
        );
      case TipoServicio.edredones:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EdredonesScreen()),
        );
      case TipoServicio.lavadoYPlegado:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LavadoKiloScreen()),
        );
    }
  }

  void _onTabSelected(AppBottomTab tab) {
    switch (tab) {
      case AppBottomTab.home:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeClienteScreen()),
        );
      case AppBottomTab.services:
        break;
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
    final reales = context.watch<ServiciosProvider>().activos;
    final items = catalogoParaMostrar(reales);
    final servicios = items.where((s) => s.nombre.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_laundry_service_rounded, color: AppColors.primary, size: 26),
            const SizedBox(width: 8),
            Text(
              'FreshClean',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.secondary),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
              ),
            ),
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
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Buscar servicios...',
                  hintStyle: GoogleFonts.inter(color: AppColors.outline),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (servicios.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No encontramos servicios con ese nombre',
                      style: GoogleFonts.inter(color: AppColors.secondary),
                    ),
                  ),
                )
              else
                for (final servicio in servicios) ...[
                  _ServicioCard(
                    servicio: servicio,
                    onTap: () => _onServicioTap(context, servicio.tipo),
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppBottomTab.services,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class _ServicioCard extends StatelessWidget {
  const _ServicioCard({required this.servicio, required this.onTap});

  final ServicioDisplay servicio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: servicio.destacado
                    ? AppColors.primaryFixed
                    : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(servicio.icon, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              servicio.nombre,
              style: GoogleFonts.inter(
                fontSize: servicio.destacado ? 26 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              servicio.descripcion,
              style: GoogleFonts.inter(
                fontSize: servicio.destacado ? 16 : 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  servicio.precioTexto,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
