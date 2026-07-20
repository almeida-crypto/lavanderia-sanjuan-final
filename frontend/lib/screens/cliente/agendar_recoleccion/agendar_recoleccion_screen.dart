import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/direccion.dart';
import '../../../models/fragancia.dart';
import '../../../models/franja_horaria.dart';
import '../../../models/servicio.dart';
import '../../../models/servicio_lavanderia.dart';
import '../../../models/tarjeta.dart';
import '../../../providers/agendar_recoleccion_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/direcciones_provider.dart';
import '../../../providers/metodos_pago_provider.dart';
import '../../../providers/preferencias_provider.dart';
import '../../../providers/servicios_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../home_cliente/home_cliente_screen.dart';
import '../mi_perfil/formulario_direccion_screen.dart';
import '../mi_perfil/mi_perfil_screen.dart';
import '../mi_perfil/seleccionar_direccion_screen.dart';
import '../mi_perfil/seleccionar_metodo_pago_screen.dart';
import '../mis_pedidos/mis_pedidos_screen.dart';
import '../servicios/servicios_screen.dart';
import 'pedido_recibido_screen.dart';

const _diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

String _etiquetaChip(int index, DateTime fecha) {
  if (index == 0) return 'Hoy';
  if (index == 1) return 'Mañ';
  return _diasSemana[fecha.weekday - 1];
}

class AgendarRecoleccionScreen extends StatelessWidget {
  const AgendarRecoleccionScreen({super.key});

  static Route<void> route({
    TipoServicio? servicioInicial,
    int cantidadInicial = 1,
    OpcionAcabado? opcionAcabadoInicial,
  }) {
    return MaterialPageRoute(
      builder: (context) {
        final preferencias = context.read<PreferenciasProvider>();
        final servicioReal = servicioInicial == null
            ? null
            : context.read<ServiciosProvider>().paraTipo(servicioInicial);
        return ChangeNotifierProvider(
          create: (_) => AgendarRecoleccionProvider(
            servicioInicial: servicioInicial,
            servicioReal: servicioReal,
            opcionAcabadoInicial: opcionAcabadoInicial,
            ecoFriendlyInicial: preferencias.ecoFriendly,
            fraganciaInicial: preferencias.fragancia,
            cantidadInicial: cantidadInicial,
          ),
          child: const AgendarRecoleccionScreen(),
        );
      },
    );
  }

  void _onTabSelected(BuildContext context, AppBottomTab tab) {
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MiPerfilScreen()),
        );
    }
  }

  Future<void> _submit(
    BuildContext context,
    AgendarRecoleccionProvider provider,
    Direccion? direccionActual,
  ) async {
    if (direccionActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega una dirección de recolección primero.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final pedido = await provider.agendarRecoleccion(
      clienteId: auth.currentUser?.id ?? '2',
      clienteNombre: auth.currentUser?.nombre ?? 'Cliente Demo',
      clienteEmail: auth.currentUser?.correo,
      clienteTelefono: auth.currentUser?.telefono,
    );
    if (!context.mounted) return;

    if (pedido == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo agendar el pedido. Intenta de nuevo.')),
      );
      return;
    }

    final franjaInfo = franjasDisponibles.firstWhere(
      (f) => f.valor == provider.franja,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PedidoRecibidoScreen(
          pedido: pedido,
          direccionTitulo: direccionActual.titulo,
          direccionLinea: direccionActual.lineas.join(', '),
          horarioTexto: '${franjaInfo.etiqueta} (${franjaInfo.horario})',
        ),
      ),
    );
  }

  Future<void> _seleccionarDireccion(
    BuildContext context,
    AgendarRecoleccionProvider provider,
    Direccion? direccionActual,
  ) async {
    if (direccionActual == null) {
      // Todavía no hay ninguna dirección guardada: se va directo al alta
      // en vez de un selector que no tendría nada que mostrar.
      final nueva = await Navigator.of(context).push<Direccion>(
        MaterialPageRoute(builder: (_) => const FormularioDireccionScreen()),
      );
      if (nueva != null && context.mounted) {
        try {
          final guardada = await context.read<DireccionesProvider>().agregar(nueva);
          provider.seleccionarDireccion(guardada);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo guardar la dirección')),
            );
          }
        }
      }
      return;
    }

    final resultado = await Navigator.of(context).push<Direccion>(
      MaterialPageRoute(
        builder: (_) =>
            SeleccionarDireccionScreen(seleccionActual: direccionActual),
      ),
    );
    if (resultado != null) {
      provider.seleccionarDireccion(resultado);
    }
  }

  Future<void> _seleccionarTarjeta(
    BuildContext context,
    AgendarRecoleccionProvider provider,
    TarjetaGuardada? tarjetaActual,
  ) async {
    final resultado = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => SeleccionarMetodoPagoScreen(
          seleccionActual: tarjetaActual,
          esEfectivoInicial: provider.esPagoEfectivo,
        ),
      ),
    );
    if (resultado == 'efectivo') {
      provider.seleccionarEfectivo();
    } else if (resultado is TarjetaGuardada) {
      provider.seleccionarTarjeta(resultado);
    }
  }

  Future<void> _aplicarCodigoPromocional(
    BuildContext context,
    AgendarRecoleccionProvider provider,
  ) async {
    await provider.aplicarCodigoPromocional();
    if (!context.mounted) return;
    final mensaje = provider.mensajePromo;
    if (mensaje != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendarRecoleccionProvider>();
    final direccionActual =
        provider.direccionSeleccionada ??
        context.watch<DireccionesProvider>().predeterminada;
    final tarjetaActual = provider.esPagoEfectivo
        ? null
        : (provider.tarjetaSeleccionada ??
            context.watch<MetodosPagoProvider>().principal);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Agendar Recolección',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Dirección'),
              const SizedBox(height: 16),
              _AddressCard(
                direccion: direccionActual,
                onTap: () =>
                    _seleccionarDireccion(context, provider, direccionActual),
              ),
              const SizedBox(height: 32),
              const _SectionTitle('Fecha'),
              const SizedBox(height: 16),
              _DateSelector(provider: provider),
              const SizedBox(height: 32),
              const _SectionTitle('Horario'),
              const SizedBox(height: 16),
              _TimeWindowSelector(provider: provider),
              const SizedBox(height: 32),
              const _SectionTitle('Método de Pago'),
              const SizedBox(height: 16),
              _PaymentCard(
                tarjeta: tarjetaActual,
                esEfectivo: provider.esPagoEfectivo || tarjetaActual == null,
                onTap: () => _seleccionarTarjeta(context, provider, tarjetaActual),
              ),
              const SizedBox(height: 32),
              const _SectionTitle('Preferencias del Pedido'),
              const SizedBox(height: 4),
              Text(
                'Se usan tus preferencias predeterminadas, pero puedes cambiarlas solo para este pedido.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _PreferenciasPedidoCard(provider: provider),
              const SizedBox(height: 32),
              const _SectionTitle('Instrucciones especiales'),
              const SizedBox(height: 16),
              _InstructionsField(provider: provider),
              const SizedBox(height: 32),
              const _SectionTitle('Resumen'),
              const SizedBox(height: 16),
              _ResumenEstimadoCard(provider: provider),
              const SizedBox(height: 24),
              _ConfirmarPedidoBar(
                isLoading: provider.isLoading,
                validandoPromo: provider.validandoPromo,
                codigoPromoController: provider.codigoPromoController,
                onAplicarCodigo: () => _aplicarCodigoPromocional(context, provider),
                onConfirmar: () => _submit(context, provider, direccionActual),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppBottomTab.orders,
        onTabSelected: (tab) => _onTabSelected(context, tab),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.direccion, required this.onTap});

  final Direccion? direccion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final direccion = this.direccion;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondaryContainer),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                direccion?.icon ?? Icons.add_location_alt_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: direccion == null
                  ? Text(
                      'Agregar dirección de recolección',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          direccion.titulo,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          direccion.lineas.join(', '),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.tarjeta,
    required this.esEfectivo,
    required this.onTap,
  });

  final TarjetaGuardada? tarjeta;
  final bool esEfectivo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tarjetaActual = esEfectivo ? null : tarjeta;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondaryContainer),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                esEfectivo ? Icons.payments_outlined : Icons.credit_card_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: esEfectivo
                  ? Text(
                      'Efectivo contra entrega',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    )
                  : (tarjetaActual == null
                      ? Text(
                          'Agregar método de pago',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tarjetaActual.marca == MarcaTarjeta.mastercard ? 'Mastercard' : 'Visa'} **** ${tarjetaActual.ultimosDigitos}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vence ${tarjetaActual.expira}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        )),
            ),
            const SizedBox(width: 8),
            Text(
              (esEfectivo || tarjetaActual != null) ? 'Cambiar' : 'Agregar',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenciasPedidoCard extends StatelessWidget {
  const _PreferenciasPedidoCard({required this.provider});

  final AgendarRecoleccionProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryContainer),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Eco-friendly',
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface),
                ),
              ),
              Switch(
                value: provider.ecoFriendly,
                onChanged: provider.alternarEcoFriendly,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            'Fragancia',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final fragancia in fraganciasDisponibles)
                _FraganciaChip(
                  label: fragancia.nombre,
                  seleccionada: provider.fragancia == fragancia.nombre,
                  onTap: () => provider.seleccionarFragancia(fragancia.nombre),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FraganciaChip extends StatelessWidget {
  const _FraganciaChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class _ResumenEstimadoCard extends StatelessWidget {
  const _ResumenEstimadoCard({required this.provider});

  final AgendarRecoleccionProvider provider;

  @override
  Widget build(BuildContext context) {
    final unidad = provider.unidad;
    final unidadPlural = provider.cantidad == 1 ? unidad : '${unidad}s';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryContainer),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cantidad aproximada',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
              Text(
                '${provider.cantidad} $unidadPlural',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          if (provider.opcionAcabado != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.opcionAcabado!.nombre,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  provider.opcionAcabado!.precioAdicional == 0
                      ? 'Sin costo extra'
                      : '+\$${provider.opcionAcabado!.precioAdicional.toStringAsFixed(2)}/$unidad',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Estimado',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                '\$${provider.totalConDescuento.toStringAsFixed(2)} MXN',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Este total es una referencia. El precio final se confirma cuando se pesa o verifica tu pedido en la recolección.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.provider});

  final AgendarRecoleccionProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.fechasDisponibles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final fecha = provider.fechasDisponibles[index];
          final selected = fecha == provider.fechaSeleccionada;
          return InkWell(
            onTap: () => provider.seleccionarFecha(fecha),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _etiquetaChip(index, fecha).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: selected
                          ? AppColors.primaryFixedDim
                          : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${fecha.day}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeWindowSelector extends StatelessWidget {
  const _TimeWindowSelector({required this.provider});

  final AgendarRecoleccionProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: franjasDisponibles.map((franjaInfo) {
        final selected = franjaInfo.valor == provider.franja;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => provider.seleccionarFranja(franjaInfo.valor),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.surfaceContainerLowest
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    franjaInfo.icon,
                    color: selected ? AppColors.primary : AppColors.secondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          franjaInfo.etiqueta,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          franjaInfo.horario,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.8)
                                : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<FranjaHoraria>(
                    value: franjaInfo.valor,
                    // ignore: deprecated_member_use
                    groupValue: provider.franja,
                    activeColor: AppColors.primary,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) provider.seleccionarFranja(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InstructionsField extends StatelessWidget {
  const _InstructionsField({required this.provider});

  final AgendarRecoleccionProvider provider;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: provider.instruccionesController,
      minLines: 4,
      maxLines: 4,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        hintText: 'Ej: Dejar en portería, cuidado con el perro, etc.',
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.outlineVariant,
        ),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _ConfirmarPedidoBar extends StatelessWidget {
  const _ConfirmarPedidoBar({
    required this.isLoading,
    required this.validandoPromo,
    required this.codigoPromoController,
    required this.onAplicarCodigo,
    required this.onConfirmar,
  });

  final bool isLoading;
  final bool validandoPromo;
  final TextEditingController codigoPromoController;
  final VoidCallback onAplicarCodigo;
  final VoidCallback onConfirmar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codigoPromoController,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    hintText: 'Código promocional',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.outlineVariant,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: validandoPromo ? null : onAplicarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: validandoPromo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : Text(
                          'Aplicar',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : onConfirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirmar Pedido',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
