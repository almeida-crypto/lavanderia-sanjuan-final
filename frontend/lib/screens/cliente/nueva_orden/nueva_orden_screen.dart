import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/servicio_lavanderia.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../servicios/edredones_screen.dart';
import '../servicios/lavado_kilo_screen.dart';
import '../servicios/planchado_screen.dart';
import '../servicios/servicios_screen.dart';
import '../servicios/tintoreria_screen.dart';

class NuevaOrdenScreen extends StatefulWidget {
  const NuevaOrdenScreen({super.key});

  @override
  State<NuevaOrdenScreen> createState() => _NuevaOrdenScreenState();
}

class _NuevaOrdenScreenState extends State<NuevaOrdenScreen> {
  TipoServicio? _seleccionado;

  void _onTabSelected(AppBottomTab tab) {
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

  void _continuar() {
    switch (_seleccionado) {
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
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Iniciar un Nuevo Pedido',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona el servicio que necesitas hoy.',
                style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: serviciosDisponibles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final servicio = serviciosDisponibles[index];
                  final seleccionado = servicio.tipo == _seleccionado;
                  return _ServicioTile(
                    servicio: servicio,
                    seleccionado: seleccionado,
                    onTap: () => setState(() => _seleccionado = servicio.tipo),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            color: AppColors.surface,
            child: ElevatedButton(
              onPressed: _seleccionado == null ? null : _continuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.surfaceVariant,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Continuar',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          AppBottomNavBar(
            currentTab: AppBottomTab.services,
            onTabSelected: _onTabSelected,
          ),
        ],
      ),
    );
  }
}

class _ServicioTile extends StatelessWidget {
  const _ServicioTile({
    required this.servicio,
    required this.seleccionado,
    required this.onTap,
  });

  final ServicioLavanderiaInfo servicio;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.outlineVariant,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: seleccionado ? AppColors.primary : AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                servicio.icon,
                color: seleccionado ? Colors.white : AppColors.primary,
              ),
            ),
            const Spacer(),
            Text(
              servicio.nombre,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              servicio.precioTexto,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
