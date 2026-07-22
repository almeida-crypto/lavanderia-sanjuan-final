import 'package:flutter/material.dart';

import '../models/direccion.dart';
import '../models/franja_horaria.dart';
import '../models/pedido.dart';
import '../models/promocion.dart';
import '../models/servicio.dart';
import '../models/servicio_lavanderia.dart';
import '../models/tarjeta.dart';
import '../services/pedido_service.dart';
import '../services/promocion_service.dart';

class AgendarRecoleccionProvider extends ChangeNotifier {
  final _promocionService = PromocionService();

  AgendarRecoleccionProvider({
    TipoServicio? servicioInicial,
    this.servicioReal,
    OpcionAcabado? opcionAcabadoInicial,
    String fraganciaInicial = 'Lavanda',
    int cantidadInicial = 1,
  }) : fechasDisponibles = _generarFechas(),
       _servicio = servicioInicial ?? TipoServicio.lavadoYPlegado,
       _opcionAcabado = opcionAcabadoInicial,
       _fragancia = fraganciaInicial,
       _cantidad = cantidadInicial < 1 ? 1 : cantidadInicial {
    _fechaSeleccionada = fechasDisponibles.first;
  }

  /// Opción de acabado/entrega que el cliente eligió antes de llegar aquí
  /// (ej. en "Opciones de Doblado" o el modo de entrega de Planchado). Antes
  /// esa elección se perdía por completo; ahora sí llega al pedido creado.
  OpcionAcabado? _opcionAcabado;
  OpcionAcabado? get opcionAcabado => _opcionAcabado;

  /// Precio/nombre/unidad reales tal como los configuró el administrador
  /// (via ServiciosProvider). Si no llegaron (backend caído o servicio sin
  /// coincidencia), se cae al valor de referencia estático [servicioInfo].
  final Servicio? servicioReal;

  /// Cantidad aproximada (kg o piezas, según el servicio) que el cliente
  /// eligió como referencia. Es solo una estimación: el total real se
  /// confirma cuando el pedido se pesa/verifica en la recolección.
  final int _cantidad;
  int get cantidad => _cantidad;

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

  /// El cliente lleva su ropa a la sucursal él mismo, en vez de que un
  /// repartidor pase a recogerla a domicilio.
  bool _recoleccionEnSucursal = false;
  bool get recoleccionEnSucursal => _recoleccionEnSucursal;

  void seleccionarRecoleccionEnSucursal(bool valor) {
    _recoleccionEnSucursal = valor;
    notifyListeners();
  }

  /// El cliente recoge su ropa en la sucursal él mismo, en vez de que un
  /// repartidor se la lleve a domicilio.
  bool _entregaEnSucursal = false;
  bool get entregaEnSucursal => _entregaEnSucursal;

  void seleccionarEntregaEnSucursal(bool valor) {
    _entregaEnSucursal = valor;
    notifyListeners();
  }

  /// Si el cliente va a llevar y recoger todo en la sucursal, no hace falta
  /// que tenga una dirección guardada solo para este pedido.
  bool get necesitaDireccion => !(_recoleccionEnSucursal && _entregaEnSucursal);

  TarjetaGuardada? _tarjetaSeleccionada;
  TarjetaGuardada? get tarjetaSeleccionada => _tarjetaSeleccionada;

  bool _esPagoEfectivo = false;
  bool get esPagoEfectivo => _esPagoEfectivo;

  void seleccionarEfectivo() {
    _esPagoEfectivo = true;
    _tarjetaSeleccionada = null;
    notifyListeners();
  }

  void seleccionarTarjeta(TarjetaGuardada tarjeta) {
    _esPagoEfectivo = false;
    _tarjetaSeleccionada = tarjeta;
    notifyListeners();
  }

  final codigoPromoController = TextEditingController();
  Promocion? _promoAplicada;
  String? _mensajePromo;
  bool _validandoPromo = false;
  String? get mensajePromo => _mensajePromo;
  bool get validandoPromo => _validandoPromo;

  /// Fracción de descuento a aplicar sobre el total (0 si no hay código
  /// vigente aplicado). El % y la vigencia los define el admin en el panel;
  /// aquí solo se valida contra lo que el backend realmente tiene guardado.
  double get tasaDescuento => (_promoAplicada?.descuentoPorcentaje ?? 0) / 100;

  /// Valida el código contra el backend (vigencia, servicio, cantidad
  /// mínima de prendas y usos ya gastados por ESTE cliente, identificado por
  /// el token de sesión) en vez de decidirlo solo con lo que se ve en el
  /// celular; así un código con "1 uso por cliente" de verdad no se puede
  /// reutilizar.
  Future<void> aplicarCodigoPromocional() async {
    final codigo = codigoPromoController.text.trim().toUpperCase();
    if (codigo.isEmpty) return;

    _validandoPromo = true;
    notifyListeners();
    try {
      final encontrada = await _promocionService.validar(
        codigo: codigo,
        servicio: nombreServicio,
        cantidad: _cantidad,
      );
      _promoAplicada = encontrada;
      _mensajePromo = '¡Código aplicado! ${encontrada.descuentoPorcentaje.round()}% de descuento.';
    } on PromocionException catch (e) {
      _promoAplicada = null;
      _mensajePromo = e.message;
    } catch (_) {
      _promoAplicada = null;
      _mensajePromo = 'No se pudo validar el código, intenta de nuevo.';
    } finally {
      _validandoPromo = false;
      notifyListeners();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ServicioLavanderiaInfo get servicioInfo =>
      serviciosDisponibles.firstWhere((s) => s.tipo == _servicio);

  /// Nombre real del servicio (el que administra el admin) para mandar al
  /// backend; si no hay coincidencia real, usa el nombre de referencia.
  String get nombreServicio => servicioReal?.nombre ?? servicioInfo.nombre;

  String get unidad => servicioReal?.unidad ?? servicioInfo.unidad;

  double get _precioUnitario =>
      (servicioReal?.precio ?? servicioInfo.totalEstimado);

  double get montoOpcionAcabado => _opcionAcabado?.precioAdicional ?? 0;

  double get totalEstimado => _precioUnitario * _cantidad + montoOpcionAcabado;

  double get descuento => totalEstimado * tasaDescuento;

  double get totalConDescuento =>
      (totalEstimado - descuento).clamp(0, double.infinity).toDouble();

  void seleccionarServicio(TipoServicio tipo) {
    _servicio = tipo;
    notifyListeners();
  }

  void seleccionarOpcionAcabado(OpcionAcabado? opcion) {
    _opcionAcabado = opcion;
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
      final tarjeta = _esPagoEfectivo ? null : _tarjetaSeleccionada;
      final metodoPago = tarjeta == null
          ? 'Efectivo contra entrega'
          : '${tarjeta.marca == MarcaTarjeta.mastercard ? 'Mastercard' : 'Visa'} •••• ${tarjeta.ultimosDigitos}';

      final direccionTexto = direccionSeleccionada?.titulo ??
          (_recoleccionEnSucursal && _entregaEnSucursal
              ? 'Recolección y entrega en sucursal'
              : 'Dirección no definida');

      final creado = await pedidoService.crearPedido({
        'clienteId': clienteId ?? '2',
        'clienteNombre': clienteNombre ?? 'Cliente Demo',
        'clienteEmail': clienteEmail,
        'clienteTelefono': clienteTelefono,
        'servicio': nombreServicio,
        'fecha': _fechaSeleccionada.toIso8601String(),
        'franjaHoraria': franjaEtiqueta,
        'direccion': direccionTexto,
        'instrucciones': instruccionesController.text.trim(),
        'fragancia': _fragancia,
        'cantidadAproximada': _cantidad,
        'metodoPago': metodoPago,
        'opcionAcabado': _opcionAcabado?.nombre,
        'precioAcabado': _opcionAcabado == null ? null : montoOpcionAcabado,
        'codigoPromocion': _promoAplicada?.codigo,
        'total': totalConDescuento,
        'recoleccionEnSucursal': _recoleccionEnSucursal,
        'entregaEnSucursal': _entregaEnSucursal,
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
