import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/servicio_lavanderia.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../agendar_recoleccion/agendar_recoleccion_screen.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import 'servicios_screen.dart';

class _PasoProceso {
  const _PasoProceso({required this.titulo, required this.descripcion});

  final String titulo;
  final String descripcion;
}

const _pasos = [
  _PasoProceso(
    titulo: 'Revisión',
    descripcion:
        'Inspección minuciosa de cada prenda para identificar manchas y áreas de cuidado especial.',
  ),
  _PasoProceso(
    titulo: 'Tratamiento',
    descripcion: 'Aplicación de solventes biodegradables y técnicas de desmanchado artesanal.',
  ),
  _PasoProceso(
    titulo: 'Acabado Final',
    descripcion: 'Planchado profesional al vapor y empaque en fundas protectoras transpirables.',
  ),
];

const _prendasSugeridas = [
  (icon: Icons.dry_cleaning_rounded, label: 'Trajes'),
  (icon: Icons.checkroom_rounded, label: 'Abrigos'),
  (icon: Icons.spa_rounded, label: 'Vestidos Seda'),
  (icon: Icons.diamond_rounded, label: 'Diseñador'),
];

class _TarifaTier {
  const _TarifaTier({
    required this.nombre,
    required this.precio,
    required this.incluye,
    this.destacado = false,
  });

  final String nombre;
  final String precio;
  final List<String> incluye;
  final bool destacado;
}

const _tarifas = [
  _TarifaTier(
    nombre: 'Básica',
    precio: '\$12',
    incluye: ['Limpieza estándar', 'Planchado básico'],
  ),
  _TarifaTier(
    nombre: 'Premium',
    precio: '\$25',
    incluye: ['Desmanchado profundo', 'Vaporizado manual', 'Seguro de prenda'],
    destacado: true,
  ),
  _TarifaTier(
    nombre: 'Luxury',
    precio: '\$45',
    incluye: ['Cuidado de pedrería', 'Entrega en percha premium'],
  ),
];

class TintoreriaScreen extends StatefulWidget {
  const TintoreriaScreen({super.key});

  @override
  State<TintoreriaScreen> createState() => _TintoreriaScreenState();
}

class _TintoreriaScreenState extends State<TintoreriaScreen> {
  int _tierSeleccionado = 1;

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

  void _contratarAhora() {
    Navigator.of(context).push(
      AgendarRecoleccionScreen.route(servicioInicial: TipoServicio.tintoreria),
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
              _HeroBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeaderCard(),
                    const SizedBox(height: 32),
                    _SectionHeader(icon: Icons.analytics_outlined, title: '¿Cómo funciona?'),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _pasos.length; i++) ...[
                      _PasoTile(numero: i + 1, paso: _pasos[i]),
                      if (i != _pasos.length - 1) const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 32),
                    _SectionHeader(icon: Icons.checkroom_outlined, title: 'Prendas sugeridas'),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _prendasSugeridas.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                      ),
                      itemBuilder: (context, index) {
                        final prenda = _prendasSugeridas[index];
                        return _PrendaTile(icon: prenda.icon, label: prenda.label);
                      },
                    ),
                    const SizedBox(height: 32),
                    const _InstruccionesEspecialesCard(),
                    const SizedBox(height: 32),
                    _SectionHeader(icon: Icons.sell_outlined, title: 'Tarifas'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _tarifas.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _TarifaCard(
                      tarifa: _tarifas[index],
                      seleccionada: _tierSeleccionado == index,
                      onTap: () => setState(() => _tierSeleccionado = index),
                    );
                  },
                ),
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
            child: ElevatedButton.icon(
              onPressed: _contratarAhora,
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
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
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
  const _HeaderCard();

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
            'Cuidado experto para tus prendas más delicadas. Utilizamos procesos de limpieza en seco ecológicos que eliminan manchas difíciles sin dañar las fibras.',
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

class _PasoTile extends StatelessWidget {
  const _PasoTile({required this.numero, required this.paso});

  final int numero;
  final _PasoProceso paso;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$numero',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paso.titulo,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paso.descripcion,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrendaTile extends StatelessWidget {
  const _PrendaTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
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

class _TarifaCard extends StatelessWidget {
  const _TarifaCard({
    required this.tarifa,
    required this.seleccionada,
    required this.onTap,
  });

  final _TarifaTier tarifa;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final destacado = tarifa.destacado;
    final bgColor = destacado ? AppColors.primary : AppColors.surfaceContainerLowest;
    final textColor = destacado ? Colors.white : AppColors.onSurface;
    final mutedColor = destacado ? Colors.white70 : AppColors.onSurfaceVariant;

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
          boxShadow: destacado
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tarifa.nombre.toUpperCase(),
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
                  tarifa.precio,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ prenda',
                  style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in tarifa.incluye)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: textColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(fontSize: 13, color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
