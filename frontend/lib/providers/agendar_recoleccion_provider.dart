import 'package:flutter/material.dart';

import '../models/direccion.dart';
import '../models/franja_horaria.dart';
import '../models/pedido.dart';
import '../models/servicio_lavanderia.dart';
import '../models/tarjeta.dart';
import '../services/pedido_service.dart';

const _codigoPromoCorrecto = 'FRESH20';
const _tasaDescuentoPromo = 0.20;

class AgendarRecoleccionProvider extends ChangeNotifier {
  AgendarRecoleccionProvider({
    TipoServicio? servicioInicial,
    bool ecoFriendlyInicial = false,
    String fraganciaInicial = 'Lavanda',
    int cantidadInicial = 1,
  }) : fechasDisponibles = _generarFechas(),
       _servicio = servicioInicial ?? TipoServicio.lavadoYPlegado,
       _ecoFriendly = ecoFriendlyInicial,
       _fragancia = fraganciaInicial,
       _cantidad = cantidadInicial < 1 ? 1 : cantidadInicial {
    _fechaSeleccionada = fechasDisponibles.first;
  }

  /// Cantidad aproximada (kg o piezas, según el servicio) que el cliente
  /// eligió como referencia. Es solo una estimación: el total real se
  /// confirma cuando el pedido se pesa/verifica en la recolección.
  final int _cantidad;
  int get cantidad => _cantidad;

  /// Preferencias del pedido: arrancan con el valor predeterminado del
  /// cliente (Ajustes), pero se pueden cambiar solo para este pedido sin
  /// afectar su preferencia guardada.
  bool _ecoFriendly;
  bool get ecoFriendly => _ecoFriendly;

  void alternarEcoFriendly(bool valor) {
    _ecoFriendly = valor;
    notifyListeners();
  }

  String _fragancia;
  String get fragancia => _fragancia;

  void seleccionarFragancia(String valor) {
    _fragancia = valor;
    notifyListeners();
  }

  static List<DateTime> _generarFechas() {
    final hoy = DateTime.now();
    return List.generate(7, (i) => DateTime(hoy.year, hoy.month, hoy.day + i));
  }

  final List<DateTime> fechasDisponibles;
  final instruccionesController = TextEditingController();

  TipoServicio _servicio;
  TipoServicio get servicio => _servicio;

  late DateTime _fechaSeleccionada;
  DateTime get fechaSeleccionada => _fechaSeleccionada;

  FranjaHoraria _franja = FranjaHoraria.tarde;
  FranjaHoraria get franja => _franja;

  Direccion? _direccionSeleccionada;
  Direccion? get direccionSeleccionada => _direccionSeleccionada;

  void seleccionarDireccion(Direccion direccion) {
    _direccionSeleccionada = direccion;
    notifyListeners();
  }

  TarjetaGuardada? _tarjetaSeleccionada;
  TarjetaGuardada? get tarjetaSeleccionada => _tarjetaSeleccionada;

  void seleccionarTarjeta(TarjetaGuardada tarjeta) {
    _tarjetaSeleccionada = tarjeta;
    notifyListeners();
  }

  final codigoPromoController = TextEditingController();
  bool _codigoPromoValido = false;
  String? _mensajePromo;
  String? get mensajePromo => _mensajePromo;

  /// Fracción de descuento a aplicar sobre el total (0 si no hay código válido).
  double get tasaDescuento => _codigoPromoValido ? _tasaDescuentoPromo : 0;

  void aplicarCodigoPromocional() {
    final codigo = codigoPromoController.text.trim().toUpperCase();
    if (codigo.isEmpty) return;
    _codigoPromoValido = codigo == _codigoPromoCorrecto;
    _mensajePromo = _codigoPromoValido
        ? '¡Código aplicado! ${(_tasaDescuentoPromo * 100).round()}% de descuento.'
        : 'Código promocional no válido.';
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ServicioLavanderiaInfo get servicioInfo =>
      serviciosDisponibles.firstWhere((s) => s.tipo == _servicio);

  double get totalEstimado => servicioInfo.totalEstimado * _cantidad;

  double get descuento => totalEstimado * tasaDescuento;

  double get totalConDescuento =>
      (totalEstimado - descuento).clamp(0, double.infinity).toDouble();

  void seleccionarServicio(TipoServicio tipo) {
    _servicio = tipo;
    notifyListeners();
  }

  void seleccionarFecha(DateTime fecha) {
    _fechaSeleccionada = fecha;
    notifyListeners();
  }

  void seleccionarFranja(FranjaHoraria franja) {
    _franja = franja;
    notifyListeners();
  }

  /// Crea el pedido en el backend y devuelve el pedido real ya creado
  /// (con su ID real), para que la pantalla de confirmación y el
  /// seguimiento no dependan de datos inventados.
  Future<Pedido?> agendarRecoleccion({
    String? clienteId,
    String? clienteNombre,
    String? clienteEmail,
    String? clienteTelefono,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final pedidoService = PedidoService();
      final franjaEtiqueta = franjasDisponibles
          .firstWhere((f) => f.valor == _franja)
          .etiqueta;
      final tarjeta = _tarjetaSeleccionada;
      final metodoPago = tarjeta == null
          ? 'Efectivo contra entrega'
          : '${tarjeta.marca == MarcaTarjeta.mastercard ? 'Mastercard' : 'Visa'} •••• ${tarjeta.ultimosDigitos}';

      final creado = await pedidoService.crearPedido({
        'clienteId': clienteId ?? '2',
        'clienteNombre': clienteNombre ?? 'Cliente Demo',
        'clienteEmail': clienteEmail,
        'clienteTelefono': clienteTelefono,
        'servicio': servicioInfo.nombre,
        'fecha': _fechaSeleccionada.toIso8601String(),
        'franjaHoraria': franjaEtiqueta,
        'direccion': direccionSeleccionada?.titulo ?? 'Dirección no definida',
        'instrucciones': instruccionesController.text.trim(),
        'ecoFriendly': _ecoFriendly,
        'fragancia': _fragancia,
        'cantidadAproximada': _cantidad,
        'metodoPago': metodoPago,
        'total': totalConDescuento,
      });
      return Pedido.fromJson(creado);
    } catch (_) {
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    instruccionesController.dispose();
    codigoPromoController.dispose();
    super.dispose();
  }
}
