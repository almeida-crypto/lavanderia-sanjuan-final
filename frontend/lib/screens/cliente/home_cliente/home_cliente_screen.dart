import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/pedido.dart';
import '../../../models/promocion.dart';
import '../../../models/servicio_display.dart';
import '../../../models/servicio_lavanderia.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/servicios_provider.dart';
import '../../../services/pedido_service.dart';
import '../../../services/promocion_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../../../widgets/doble_back_para_salir.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../nueva_orden/nueva_orden_screen.dart';
import '../pedido/pedido_screen.dart';
import '../servicios/edredones_screen.dart';
import '../servicios/lavado_kilo_screen.dart';
import '../servicios/planchado_screen.dart';
import '../servicios/servicios_screen.dart';
import '../servicios/tintoreria_screen.dart';
import 'detalle_oferta_screen.dart';
import 'ofertas_screen.dart';

class HomeClienteScreen extends StatefulWidget {
  const HomeClienteScreen({super.key});

  @override
  State<HomeClienteScreen> createState() => _HomeClienteScreenState();
}
class _HomeClienteScreenState extends State<HomeClienteScreen> {
  final _pedidoService = PedidoService();
  final _promocionService = PromocionService();
  bool _isLoading = true;
  Pedido? _pedidoActivo;
  List<Promocion> _promocionesVigentes = [];

  @override
  void initState() {
    super.initState();
    _cargarPedidoActivo();
    _cargarPromocionVigente();
    context.read<ServiciosProvider>().cargar();
  }

  Future<void> _cargarPromocionVigente() async {
    try {
      final promociones = await _promocionService.listar();
      final vigentes = promociones.where((p) => p.vigente).toList();
      if (mounted) setState(() => _promocionesVigentes = vigentes);
    } catch (_) {
      // Sin ofertas si el backend no responde; el banner simplemente no aparece.
    }
  }

  Future<void> _cargarPedidoActivo() async {
    final auth = context.read<AuthProvider>();
    setState(() => _isLoading = true);
    try {
      final data = await _pedidoService.listarPedidos(clienteId: auth.currentUser?.id);
      final pedidos = data.map(Pedido.fromJson);
      Pedido? activo;
      for (final pedido in pedidos) {
        if (pedido.estado == EstadoPedido.enProceso || pedido.estado == EstadoPedido.atencion) {
          activo = pedido;
          break;
        }
      }
      if (mounted) setState(() => _pedidoActivo = activo);
    } catch (_) {
      if (mounted) setState(() => _pedidoActivo = null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _onTabSelected(BuildContext context, AppBottomTab tab) {
    switch (tab) {
      case AppBottomTab.home:
        break;
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
    final nombre = context.watch<AuthProvider>().currentUser?.nombre ?? 'Usuario';

    return DobleBackParaSalir(
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 26),
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.secondary),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
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
              _Greeting(nombre: nombre),
              const SizedBox(height: 24),
              _HeroBanner(
                onOrderNow: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NuevaOrdenScreen()),
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_pedidoActivo != null)
                _ActiveOrderSection(
                  pedido: _pedidoActivo!,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PedidoScreen(pedido: _pedidoActivo!)),
                  ),
                )
              else
                _SinPedidoActivoCard(
                  onOrdenar: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NuevaOrdenScreen()),
                  ),
                ),
              const SizedBox(height: 32),
              _ServicesSection(
                onServicioTap: (servicio) => _onServicioTap(context, servicio),
              ),
              if (_promocionesVigentes.isNotEmpty) ...[
                const SizedBox(height: 24),
                _WeeklyOfferBanner(
                  promocion: _promocionesVigentes.first,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetalleOfertaScreen(promocion: _promocionesVigentes.first),
                    ),
                  ),
                ),
                if (_promocionesVigentes.length > 1) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OfertasScreen(promociones: _promocionesVigentes),
                        ),
                      ),
                      child: Text(
                        'Ver todas las ofertas (${_promocionesVigentes.length})',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppBottomTab.home,
        onTabSelected: (tab) => _onTabSelected(context, tab),
      ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, $nombre!',
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Bienvenido de nuevo',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onOrderNow});

  final VoidCallback onOrderNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -12,
            bottom: -16,
            child: Opacity(
              opacity: 0.12,
              child: Transform.rotate(
                angle: 0.2,
                child: const Icon(
                  Icons.local_laundry_service_rounded,
                  size: 120,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ropa fresca,\nsin esfuerzo.',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  letterSpacing: -0.24,
                  color: AppColors.onPrimaryFixed,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'Nosotros nos encargamos de tu colada mientras tú disfrutas de tu tiempo.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onPrimaryFixedVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onOrderNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ordenar Ahora',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderSection extends StatelessWidget {
  const _ActiveOrderSection({required this.pedido, required this.onTap});

  final Pedido pedido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final necesitaAtencion = pedido.estado == EstadoPedido.atencion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pedido Activo',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver detalles',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_laundry_service_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Orden ${pedido.numero}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.secondary,
                              ),
                            ),
                            Text(
                              pedido.servicio,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Ventana',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                        ),
                        Text(
                          pedido.franjaHoraria.isEmpty ? pedido.fechaFormateada : pedido.franjaHoraria,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estado',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: necesitaAtencion ? AppColors.error : AppColors.primary,
                      ),
                    ),
                    Text(
                      necesitaAtencion ? 'Atención requerida' : 'En proceso',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: necesitaAtencion ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.5,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(
                      necesitaAtencion ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: const Text('Rastrear pedido'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLow,
                      foregroundColor: AppColors.primary,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SinPedidoActivoCard extends StatelessWidget {
  const _SinPedidoActivoCard({required this.onOrdenar});

  final VoidCallback onOrdenar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            'No tienes pedidos activos',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agenda una recolección para ver aquí el seguimiento en tiempo real.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOrdenar,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ordenar Ahora'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLow,
                foregroundColor: AppColors.primary,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.onServicioTap});

  final ValueChanged<TipoServicio> onServicioTap;

  @override
  Widget build(BuildContext context) {
    final reales = context.watch<ServiciosProvider>().activos;
    final servicios = catalogoParaMostrar(reales);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: servicios.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final servicio = servicios[index];
            return _ServiceCard(
              icon: servicio.icon,
              title: servicio.nombre,
              subtitle: servicio.precioTexto,
              onTap: () => onServicioTap(servicio.tipo),
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyOfferBanner extends StatelessWidget {
  const _WeeklyOfferBanner({required this.promocion, required this.onTap});

  final Promocion promocion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondaryFixed),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OFERTA',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promocion.titulo,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: 'Usa el código: ',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: promocion.codigo,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sell_rounded, color: AppColors.primary, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
