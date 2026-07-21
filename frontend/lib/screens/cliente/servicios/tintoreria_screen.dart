import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/servicio.dart';
import '../../../models/servicio_display.dart';
import '../../../models/servicio_lavanderia.dart';
import '../../../providers/opciones_catalogo_provider.dart';
import '../../../providers/servicios_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../../../widgets/app_image.dart';
import '../agendar_recoleccion/agendar_recoleccion_screen.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import 'servicios_screen.dart';

class TintoreriaScreen extends StatefulWidget {
  const TintoreriaScreen({super.key});

  @override
  State<TintoreriaScreen> createState() => _TintoreriaScreenState();
}

class _TintoreriaScreenState extends State<TintoreriaScreen> {
  int _tierSeleccionado = 0;
  int _cantidad = 1;

  void _incrementarCantidad() => setState(() => _cantidad++);

  void _decrementarCantidad() {
    if (_cantidad > 1) setState(() => _cantidad--);
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

  void _contratarAhora(List<OpcionAcabado> opciones) {
    final tier = opciones.isEmpty ? null : opciones[_tierSeleccionado.clamp(0, opciones.length - 1)];
    Navigator.of(context).push(
      AgendarRecoleccionScreen.route(
        servicioInicial: TipoServicio.tintoreria,
        opcionAcabadoInicial: tier,
        cantidadInicial: _cantidad,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicio = context.watch<ServiciosProvider>().paraTipo(TipoServicio.tintoreria);
    final estatica = infoEstaticaParaTipo(TipoServicio.tintoreria);
    final comoFunciona = (servicio?.comoFunciona.isNotEmpty ?? false) ? servicio!.comoFunciona : estatica.descripcion;
    final sugeridos = servicio?.itemsSugeridos ?? [];
    final catalogo = context.watch<OpcionesCatalogoProvider>().opciones;
    final opciones = resolverOpcionesAcabado(servicio?.opcionesAcabado ?? [], catalogo);
    final tierIndex = opciones.isEmpty ? 0 : _tierSeleccionado.clamp(0, opciones.length - 1);
    final precioBase = servicio?.precio ?? estatica.totalEstimado;
    final unidad = servicio?.unidad ?? estatica.unidad;

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
          'FreshClean',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBanner(imagenUrl: servicio?.imagenUrl),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(precioBase: precioBase, unidad: unidad),
                    const SizedBox(height: 32),
                    _SectionHeader(icon: Icons.analytics_outlined, title: '¿Cómo funciona?'),
                    const SizedBox(height: 12),
                    Text(
                      comoFunciona,
                      style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.onSurfaceVariant),
                    ),
                    if (sugeridos.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _SectionHeader(icon: Icons.checkroom_outlined, title: 'Prendas sugeridas'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final prenda in sugeridos) _PrendaTile(label: prenda),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    const _InstruccionesEspecialesCard(),
                    const SizedBox(height: 32),
                    _SectionHeader(icon: Icons.add_shopping_cart_rounded, title: 'Cantidad de prendas'),
                    const SizedBox(height: 16),
                    _CantidadCard(
                      cantidad: _cantidad,
                      onIncrementar: _incrementarCantidad,
                      onDecrementar: _decrementarCantidad,
                    ),
                    if (opciones.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _SectionHeader(icon: Icons.sell_outlined, title: 'Tarifas'),
                    ],
                  ],
                ),
              ),
              if (opciones.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: opciones.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _TarifaCard(
                        opcion: opciones[index],
                        precioBase: precioBase,
                        unidad: unidad,
                        destacada: opciones.length > 1 && index == 1,
                        seleccionada: tierIndex == index,
                        onTap: () => setState(() => _tierSeleccionado = index),
                      );
                    },
                  ),
                ),
              ],
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
            child: ElevatedButton.icon(
              onPressed: () => _contratarAhora(opciones),
              icon: const Icon(Icons.shopping_basket_rounded, size: 20),
              label: Text(
                'Contratar Ahora',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  const _HeroBanner({this.imagenUrl});

  final String? imagenUrl;

  @override
  Widget build(BuildContext context) {
    if (imagenUrl != null) {
      return SizedBox(
        width: double.infinity,
        height: 200,
        child: AppImage(url: imagenUrl),
      );
    }
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryFixed, AppColors.surfaceContainerHigh],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 96,
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.precioBase, required this.unidad});

  final double precioBase;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tintorería Profesional',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Desde \$${precioBase.toStringAsFixed(2)}/$unidad. Cuidado experto para tus prendas más delicadas.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Tag('ECOLÓGICO'),
              _Tag('PREMIUM'),
              _Tag('GARANTIZADO'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _PrendaTile extends StatelessWidget {
  const _PrendaTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.checkroom_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _InstruccionesEspecialesCard extends StatelessWidget {
  const _InstruccionesEspecialesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.error),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instrucciones Especiales',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Por favor, asegúrate de vaciar los bolsillos e informar sobre manchas específicas o daños previos al recolectar tu pedido.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CantidadCard extends StatelessWidget {
  const _CantidadCard({
    required this.cantidad,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  final int cantidad;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '¿Cuántas prendas aproximadamente?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                bg: AppColors.surfaceVariant,
                iconColor: AppColors.primary,
                onTap: onDecrementar,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$cantidad',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                bg: AppColors.primary,
                iconColor: Colors.white,
                onTap: onIncrementar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _TarifaCard extends StatelessWidget {
  const _TarifaCard({
    required this.opcion,
    required this.precioBase,
    required this.unidad,
    required this.destacada,
    required this.seleccionada,
    required this.onTap,
  });

  final OpcionAcabado opcion;
  final double precioBase;
  final String unidad;
  final bool destacada;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = destacada ? AppColors.primary : AppColors.surfaceContainerLowest;
    final textColor = destacada ? Colors.white : AppColors.onSurface;
    final mutedColor = destacada ? Colors.white70 : AppColors.onSurfaceVariant;
    final precioTotal = precioBase + opcion.precioAdicional;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionada ? AppColors.primary : AppColors.outlineVariant,
            width: seleccionada ? 2 : 1,
          ),
          boxShadow: destacada
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              opcion.nombre.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${precioTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ $unidad',
                  style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                ),
              ],
            ),
            if (opcion.descripcion.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                opcion.descripcion,
                style: GoogleFonts.inter(fontSize: 13, color: textColor),
              ),
            ],
            const Spacer(),
            if (seleccionada)
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.check_circle_rounded, size: 20, color: textColor),
              ),
          ],
        ),
      ),
    );
  }
}
