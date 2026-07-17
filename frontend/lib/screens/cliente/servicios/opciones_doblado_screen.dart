import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/servicio_lavanderia.dart';
import '../../../providers/preferencias_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../../../widgets/quantity_selector.dart';
import '../agendar_recoleccion/agendar_recoleccion_screen.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import 'servicios_screen.dart';

class _OpcionDoblado {
  const _OpcionDoblado({
    required this.icon,
    required this.titulo,
    required this.precio,
    required this.descripcion,
  });

  final IconData icon;
  final String titulo;
  final String precio;
  final String descripcion;
}

const _opciones = [
  _OpcionDoblado(
    icon: Icons.inventory_2_rounded,
    titulo: 'Doblado Estándar',
    precio: '\$2.00 / kg',
    descripcion: 'Perfecto para el uso diario, doblado y apilado con cuidado.',
  ),
  _OpcionDoblado(
    icon: Icons.checkroom_rounded,
    titulo: 'Doblado en Gancho',
    precio: '\$1.50 / prenda',
    descripcion: 'Ideal para camisas y vestidos, evita las arrugas.',
  ),
  _OpcionDoblado(
    icon: Icons.auto_awesome_rounded,
    titulo: 'Doblado Especial',
    precio: '\$5.00 / prenda',
    descripcion: 'Manejo delicado para telas de lujo o piezas grandes.',
  ),
];

const _preferencias = ['Sin aroma', 'Jabón ecológico', 'Acabado con almidón', 'Envoltura de regalo'];
const _preferenciaEcoFriendly = 'Jabón ecológico';

class OpcionesDobladoScreen extends StatefulWidget {
  const OpcionesDobladoScreen({super.key});

  @override
  State<OpcionesDobladoScreen> createState() => _OpcionesDobladoScreenState();
}

class _OpcionesDobladoScreenState extends State<OpcionesDobladoScreen> {
  int _seleccionado = 0;
  int _kilos = 1;
  final Set<String> _preferenciasElegidas = {};

  void _incrementarKilos() => setState(() => _kilos++);

  void _decrementarKilos() {
    if (_kilos > 1) setState(() => _kilos--);
  }

  @override
  void initState() {
    super.initState();
    // Si el cliente ya activó "Eco-friendly" en Ajustes, no se lo volvemos a
    // preguntar aquí: arrancamos con "Jabón ecológico" preseleccionado.
    if (context.read<PreferenciasProvider>().ecoFriendly) {
      _preferenciasElegidas.add(_preferenciaEcoFriendly);
    }
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

  void _confirmarSeleccion() {
    Navigator.of(context).push(
      AgendarRecoleccionScreen.route(
        servicioInicial: TipoServicio.lavadoYPlegado,
        cantidadInicial: _kilos,
      ),
    );
  }

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
          'Opciones de Doblado',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBanner(),
              const SizedBox(height: 24),
              for (var i = 0; i < _opciones.length; i++) ...[
                _OpcionCard(
                  opcion: _opciones[i],
                  seleccionada: _seleccionado == i,
                  onTap: () => setState(() => _seleccionado = i),
                ),
                if (i != _opciones.length - 1) const SizedBox(height: 16),
              ],
              const SizedBox(height: 32),
              Text(
                'Kilos Aproximados',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Es solo una referencia para el precio estimado. El total final se confirma al pesar tu ropa en la recolección.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              QuantitySelector(
                label: 'Kilos',
                cantidad: _kilos,
                onIncrementar: _incrementarKilos,
                onDecrementar: _decrementarKilos,
              ),
              const SizedBox(height: 32),
              Text(
                'Preferencias Adicionales',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final preferencia in _preferencias)
                    _PreferenciaChip(
                      label: preferencia,
                      seleccionada: _preferenciasElegidas.contains(preferencia),
                      onTap: () => setState(() {
                        if (!_preferenciasElegidas.remove(preferencia)) {
                          _preferenciasElegidas.add(preferencia);
                        }
                      }),
                    ),
                ],
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
              onPressed: _confirmarSeleccion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirmar Selección',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          AppBottomNavBar(currentTab: AppBottomTab.services, onTabSelected: _onTabSelected),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.inverseSurface, AppColors.onSurface],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0.7, -0.7),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elige tu acabado',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personaliza cómo se te entregan tus prendas.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpcionCard extends StatelessWidget {
  const _OpcionCard({
    required this.opcion,
    required this.seleccionada,
    required this.onTap,
  });

  final _OpcionDoblado opcion;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionada ? AppColors.primary : AppColors.surfaceContainerHigh,
            width: seleccionada ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(opcion.icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                opcion.titulo,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                opcion.precio,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opcion.descripcion,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (seleccionada)
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreferenciaChip extends StatelessWidget {
  const _PreferenciaChip({
    required this.label,
    required this.seleccionada,
    required this.onTap,
  });

  final String label;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.primary : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: seleccionada ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
