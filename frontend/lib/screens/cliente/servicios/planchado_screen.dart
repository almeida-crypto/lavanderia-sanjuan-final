import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/servicio_lavanderia.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/quantity_selector.dart';
import '../agendar_recoleccion/agendar_recoleccion_screen.dart';

class _Beneficio {
  const _Beneficio({required this.icon, required this.titulo, required this.descripcion});

  final IconData icon;
  final String titulo;
  final String descripcion;
}

const _beneficios = [
  _Beneficio(
    icon: Icons.eco_rounded,
    titulo: 'Cuidado de Telas',
    descripcion:
        'Ajustamos la temperatura y nivel de vapor según la composición específica de cada prenda, evitando brillos indeseados o daños en fibras delicadas.',
  ),
  _Beneficio(
    icon: Icons.checkroom_rounded,
    titulo: 'Entrega en Gancho',
    descripcion:
        'Tus prendas se entregan listas para colgar en tu clóset. Utilizamos ganchos protectores para mantener la forma perfecta de hombros y cuellos.',
  ),
];

class PlanchadoScreen extends StatefulWidget {
  const PlanchadoScreen({super.key});

  @override
  State<PlanchadoScreen> createState() => _PlanchadoScreenState();
}

class _PlanchadoScreenState extends State<PlanchadoScreen> {
  int _piezas = 1;

  void _incrementarPiezas() => setState(() => _piezas++);

  void _decrementarPiezas() {
    if (_piezas > 1) setState(() => _piezas--);
  }

  void _contratarServicio(BuildContext context) {
    Navigator.of(context).push(
      AgendarRecoleccionScreen.route(
        servicioInicial: TipoServicio.planchado,
        cantidadInicial: _piezas,
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Planchado',
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
              _HeroSection(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.payments_rounded,
                            iconBg: AppColors.primaryFixed,
                            titulo: 'Precio',
                            valor: 'Desde \$15',
                            unidad: '/ pza',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.schedule_rounded,
                            iconBg: AppColors.secondaryFixed,
                            titulo: 'Tiempo Estimado',
                            valor: '12-24',
                            unidad: 'horas',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.local_shipping_rounded,
                            iconBg: AppColors.surfaceVariant,
                            titulo: 'Entrega',
                            valor: '',
                            unidad: 'En gancho o doblado',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Piezas Aproximadas',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Es solo una referencia para el precio estimado. El total final se confirma al contar tus prendas en la recolección.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    QuantitySelector(
                      label: 'Piezas',
                      cantidad: _piezas,
                      onIncrementar: _incrementarPiezas,
                      onDecrementar: _decrementarPiezas,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Beneficios del Servicio',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _beneficios.length; i++) ...[
                      _BeneficioTile(beneficio: _beneficios[i]),
                      if (i != _beneficios.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: ElevatedButton(
            onPressed: () => _contratarServicio(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Contratar Servicio',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 280,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryFixed, AppColors.background],
            ),
          ),
          child: Align(
            alignment: const Alignment(0, -0.5),
            child: Icon(
              Icons.iron_rounded,
              size: 88,
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.iron_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'SERVICIO ESPECIALIZADO',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Planchado Perfecto',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Acabado impecable y cuidado profesional para que tus prendas luzcan como nuevas. Utilizamos vaporización avanzada para proteger las fibras.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconBg,
    required this.titulo,
    required this.valor,
    required this.unidad,
  });

  final IconData icon;
  final Color iconBg;
  final String titulo;
  final String valor;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          if (valor.isNotEmpty)
            Text.rich(
              TextSpan(
                text: valor,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                children: [
                  TextSpan(
                    text: ' $unidad',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              unidad,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _BeneficioTile extends StatelessWidget {
  const _BeneficioTile({required this.beneficio});

  final _Beneficio beneficio;

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
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixedDim,
              shape: BoxShape.circle,
            ),
            child: Icon(beneficio.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beneficio.titulo,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  beneficio.descripcion,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
