import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/servicio_lavanderia.dart';
import '../../../utils/app_colors.dart';
import '../agendar_recoleccion/agendar_recoleccion_screen.dart';

class _Beneficio {
  const _Beneficio({required this.icon, required this.titulo, required this.descripcion});

  final IconData icon;
  final String titulo;
  final String descripcion;
}

const _beneficios = [
  _Beneficio(
    icon: Icons.sanitizer_rounded,
    titulo: 'Sanitizado Profundo',
    descripcion:
        'Proceso de lavado especializado que elimina ácaros, alérgenos y bacterias atrapadas en el relleno.',
  ),
  _Beneficio(
    icon: Icons.inventory_2_rounded,
    titulo: 'Empaque Especial',
    descripcion:
        'Se entrega en empaque protector transpirable, ideal para guardarlo durante la temporada fuera de uso.',
  ),
  _Beneficio(
    icon: Icons.waves_rounded,
    titulo: 'Secado Delicado',
    descripcion:
        'Ciclos de secado a temperatura controlada para evitar que el relleno se apelmace, manteniendo la textura esponjosa y suave original de su edredón.',
  ),
];

class EdredonesScreen extends StatefulWidget {
  const EdredonesScreen({super.key});

  @override
  State<EdredonesScreen> createState() => _EdredonesScreenState();
}

class _EdredonesScreenState extends State<EdredonesScreen> {
  int _cantidad = 1;

  void _incrementar() => setState(() => _cantidad++);

  void _decrementar() {
    if (_cantidad > 1) setState(() => _cantidad--);
  }

  void _contratarAhora() {
    Navigator.of(context).push(
      AgendarRecoleccionScreen.route(
        servicioInicial: TipoServicio.edredones,
        cantidadInicial: _cantidad,
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
              const _HeroSection(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.schedule_rounded,
                            label: 'Tiempo estimado',
                            valor: '48 horas',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.payments_rounded,
                            label: 'Precio desde',
                            valor: '\$120/pza',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Beneficios del Servicio',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final beneficio in _beneficios) ...[
                      _BeneficioCard(beneficio: beneficio),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    _SolicitarServicioCard(
                      cantidad: _cantidad,
                      onIncrementar: _incrementar,
                      onDecrementar: _decrementar,
                      onContratar: _contratarAhora,
                    ),
                  ],
                ),
              ),
            ],
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
    return Container(
      width: double.infinity,
      height: 280,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      alignment: Alignment.bottomLeft,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.inverseSurface, AppColors.onSurface],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, -0.6),
            child: Icon(
              Icons.bed_rounded,
              size: 88,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Servicio Especializado',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Edredones y\nCobertores',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Limpieza profunda para piezas de gran volumen. Eliminación de ácaros y secado delicado para mantener la suavidad.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.valor});

  final IconData icon;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
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

class _BeneficioCard extends StatelessWidget {
  const _BeneficioCard({required this.beneficio});

  final _Beneficio beneficio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(beneficio.icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            beneficio.titulo,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            beneficio.descripcion,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SolicitarServicioCard extends StatelessWidget {
  const _SolicitarServicioCard({
    required this.cantidad,
    required this.onIncrementar,
    required this.onDecrementar,
    required this.onContratar,
  });

  final int cantidad;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;
  final VoidCallback onContratar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryFixed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solicitar Servicio',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona la cantidad aproximada de edredones. El precio final se ajustará al recolectar según el tamaño.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cantidad',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
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
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onContratar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Contratar ahora',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Garantía FreshClean incluida',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
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
