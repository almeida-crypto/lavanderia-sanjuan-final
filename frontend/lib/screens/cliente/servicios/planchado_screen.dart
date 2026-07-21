import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/servicio.dart';
import '../../../models/servicio_display.dart';
import '../../../models/servicio_lavanderia.dart';
import '../../../providers/opciones_catalogo_provider.dart';
import '../../../providers/servicios_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_image.dart';
import '../../../widgets/quantity_selector.dart';
import '../agendar_recoleccion/agendar_recoleccion_screen.dart';

class PlanchadoScreen extends StatefulWidget {
  const PlanchadoScreen({super.key});

  @override
  State<PlanchadoScreen> createState() => _PlanchadoScreenState();
}

class _PlanchadoScreenState extends State<PlanchadoScreen> {
  int _piezas = 1;
  OpcionAcabado? _entregaSeleccionada;
  bool _entregaInicializada = false;

  void _incrementarPiezas() => setState(() => _piezas++);

  void _decrementarPiezas() {
    if (_piezas > 1) setState(() => _piezas--);
  }

  void _contratarServicio(BuildContext context) {
    Navigator.of(context).push(
      AgendarRecoleccionScreen.route(
        servicioInicial: TipoServicio.planchado,
        cantidadInicial: _piezas,
        opcionAcabadoInicial: _entregaSeleccionada,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicio = context.watch<ServiciosProvider>().paraTipo(TipoServicio.planchado);
    final estatica = infoEstaticaParaTipo(TipoServicio.planchado);
    final precioTexto = servicio == null
        ? estatica.precioTexto.replaceFirst('/${estatica.unidad}', '')
        : 'Desde \$${servicio.precio.toStringAsFixed(0)}';
    final tiempoEstimado = (servicio?.tiempoEstimado.isNotEmpty ?? false) ? servicio!.tiempoEstimado : '12-24 horas';
    final beneficios = servicio?.beneficios ?? [];
    final catalogo = context.watch<OpcionesCatalogoProvider>().opciones;
    final opcionesEntrega = resolverOpcionesAcabado(servicio?.opcionesAcabado ?? [], catalogo);

    if (opcionesEntrega.isNotEmpty && !_entregaInicializada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_entregaInicializada) {
          setState(() {
            _entregaSeleccionada = opcionesEntrega.first;
            _entregaInicializada = true;
          });
        }
      });
    }

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
              _HeroSection(imagenUrl: servicio?.imagenUrl),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.payments_rounded,
                            iconBg: AppColors.primaryFixed,
                            titulo: 'Precio',
                            valor: precioTexto,
                            unidad: '/ ${servicio?.unidad ?? 'pza'}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.schedule_rounded,
                            iconBg: AppColors.secondaryFixed,
                            titulo: 'Tiempo Estimado',
                            valor: tiempoEstimado,
                            unidad: '',
                          ),
                        ),
                      ],
                    ),
                    if (opcionesEntrega.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Modo de Entrega',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige cómo prefieres recibir tus prendas.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < opcionesEntrega.length; i++) ...[
                        _OpcionEntregaTile(
                          opcion: opcionesEntrega[i],
                          unidad: servicio?.unidad ?? 'pza',
                          seleccionada: _entregaSeleccionada?.nombre == opcionesEntrega[i].nombre,
                          onTap: () => setState(() => _entregaSeleccionada = opcionesEntrega[i]),
                        ),
                        if (i != opcionesEntrega.length - 1) const SizedBox(height: 12),
                      ],
                    ],
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
                    if (beneficios.isNotEmpty) ...[
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
                    ],
                    for (var i = 0; i < beneficios.length; i++) ...[
                      _BeneficioTile(beneficio: beneficios[i]),
                      if (i != beneficios.length - 1) const SizedBox(height: 12),
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
  const _HeroSection({this.imagenUrl});

  final String? imagenUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (imagenUrl != null)
          SizedBox(
            width: double.infinity,
            height: 280,
            child: AppImage(url: imagenUrl),
          )
        else
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
        if (imagenUrl != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.background.withValues(alpha: 0), AppColors.background],
                ),
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

  final BeneficioServicio beneficio;

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
            child: Icon(iconoDeBeneficio(beneficio.icono), color: AppColors.primary, size: 20),
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

class _OpcionEntregaTile extends StatelessWidget {
  const _OpcionEntregaTile({
    required this.opcion,
    required this.unidad,
    required this.seleccionada,
    required this.onTap,
  });

  final OpcionAcabado opcion;
  final String unidad;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionada ? AppColors.primary : AppColors.surfaceVariant,
            width: seleccionada ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              seleccionada ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: seleccionada ? AppColors.primary : AppColors.outlineVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opcion.nombre,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  if (opcion.descripcion.isNotEmpty)
                    Text(
                      opcion.descripcion,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (opcion.precioAdicional != 0)
              Text(
                '+\$${opcion.precioAdicional.toStringAsFixed(2)}/$unidad',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
