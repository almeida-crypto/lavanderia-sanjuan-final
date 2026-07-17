import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/direcciones_provider.dart';
import '../../../providers/metodos_pago_provider.dart';
import '../../../providers/preferencias_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../../auth/login/login_screen.dart';
import '../../auth/terminos_condiciones/politica_privacidad_screen.dart';
import '../../auth/terminos_condiciones/terminos_condiciones_screen.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../servicios/servicios_screen.dart';
import 'cambiar_contrasena_screen.dart';
import 'centro_ayuda_screen.dart';
import 'editar_perfil_screen.dart';
import 'metodos_pago_screen.dart';
import 'mis_direcciones_screen.dart';
import 'seleccionar_fragancia_screen.dart';

class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  bool _notificaciones = true;

  void _verTerminos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TerminosCondicionesScreen()),
    );
  }

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
      case AppBottomTab.orders:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MisPedidosScreen()),
        );
      case AppBottomTab.profile:
        break;
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    context.read<AuthProvider>().logout();
    context.read<PreferenciasProvider>().limpiar();
    context.read<DireccionesProvider>().limpiar();
    context.read<MetodosPagoProvider>().limpiar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().currentUser;
    final preferencias = context.watch<PreferenciasProvider>();
    final ecoFriendly = preferencias.ecoFriendly;
    final fragancia = preferencias.fragancia;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceContainerHigh, width: 4),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      usuario?.nombre ?? 'Usuario',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario?.correo ?? 'usuario@example.com',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _MenuGroup(
                titulo: 'Mi Cuenta',
                children: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Información Personal',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.location_on_outlined,
                    label: 'Direcciones',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MisDireccionesScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.payments_outlined,
                    label: 'Métodos de Pago',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MetodosPagoScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Cambiar Contraseña',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CambiarContrasenaScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MenuGroup(
                titulo: 'Preferencias',
                children: [
                  _SwitchItem(
                    icon: Icons.notifications_active_outlined,
                    label: 'Notificaciones',
                    value: _notificaciones,
                    onChanged: (value) => setState(() => _notificaciones = value),
                  ),
                  _SwitchItem(
                    icon: Icons.eco_outlined,
                    label: 'Eco-friendly',
                    value: ecoFriendly,
                    onChanged: (value) =>
                        context.read<PreferenciasProvider>().alternarEcoFriendly(value),
                  ),
                  _MenuItem(
                    icon: Icons.air_rounded,
                    label: 'Fragancia',
                    trailingText: fragancia,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SeleccionarFraganciaScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MenuGroup(
                titulo: 'Soporte y Legal',
                children: [
                  _MenuItem(
                    icon: Icons.help_center_outlined,
                    label: 'Centro de Ayuda',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CentroAyudaScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.gavel_rounded,
                    label: 'Términos y Condiciones',
                    onTap: _verTerminos,
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Política de Privacidad',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PoliticaPrivacidadScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  'Cerrar Sesión',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorContainer,
                  foregroundColor: AppColors.onErrorContainer,
                  elevation: 0,
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
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              titulo.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: AppColors.primary,
              ),
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i != 0) const Divider(height: 1, indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
