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
    bool ecoFriendlyInicial = false,
    String fraganciaInicial = 'Lavanda',
    int cantidadInicial = 1,
  }) : fechasDisponibles = _generarFechas(),
       _servicio = servicioInicial ?? TipoServicio.lavadoYPlegado,
       _opcionAcabado = opcionAcabadoInicial,
       _ecoFriendly = ecoFriendlyInicial,
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
  Promocion? _promoAplicada;
  String? _mensajePromo;
  bool _validandoPromo = false;
  String? get mensajePromo => _mensajePromo;
  bool get validandoPromo => _validandoPromo;

  /// Fracción de descuento a aplicar sobre el total (0 si no hay código
  /// vigente aplicado). El % y la vigencia los define el admin en el panel;
  /// aquí solo se valida contra lo que el backend realmente tiene guardado.
  double get tasaDescuento => (_promoAplicada?.descuentoPorcentaje ?? 0) / 100;

  Future<void> aplicarCodigoPromocional() async {
    final codigo = codigoPromoController.text.trim().toUpperCase();
    if (codigo.isEmpty) return;

    _validandoPromo = true;
    notifyListeners();
    try {
      final promociones = await _promocionService.listar();
      Promocion? encontrada;
      for (final promocion in promociones) {
        if (promocion.codigo.toUpperCase() == codigo) {
          encontrada = promocion;
          break;
        }
      }

      if (encontrada == null) {
        _promoAplicada = null;
        _mensajePromo = 'Código promocional no válido.';
      } else if (!encontrada.vigente) {
        _promoAplicada = null;
        _mensajePromo = 'Ese código ya no está vigente.';
      } else if (!encontrada.aplicaAServicio(nombreServicio)) {
        _promoAplicada = null;
        _mensajePromo = 'Ese código no aplica para "$nombreServicio".';
      } else {
        _promoAplicada = encontrada;
        _mensajePromo = '¡Código aplicado! ${encontrada.descuentoPorcentaje.round()}% de descuento.';
      }
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
      (servicioReal?.precio ?? servicioInfo.totalEstimado) + (_opcionAcabado?.precioAdicional ?? 0);

  double get totalEstimado => _precioUnitario * _cantidad;

  /// Cuánto del total corresponde a la opción de acabado elegida (para
  /// desglosarlo igual que lo hace el panel admin al mostrar el pedido).
  double get montoOpcionAcabado => (_opcionAcabado?.precioAdicional ?? 0) * _cantidad;

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
      final tarjeta = _tarjetaSeleccionada;
      final metodoPago = tarjeta == null
          ? 'Efectivo contra entrega'
          : '${tarjeta.marca == MarcaTarjeta.mastercard ? 'Mastercard' : 'Visa'} •••• ${tarjeta.ultimosDigitos}';

      final creado = await pedidoService.crearPedido({
        'clienteId': clienteId ?? '2',
        'clienteNombre': clienteNombre ?? 'Cliente Demo',
        'clienteEmail': clienteEmail,
        'clienteTelefono': clienteTelefono,
        'servicio': nombreServicio,
        'fecha': _fechaSeleccionada.toIso8601String(),
        'franjaHoraria': franjaEtiqueta,
        'direccion': direccionSeleccionada?.titulo ?? 'Dirección no definida',
        'instrucciones': instruccionesController.text.trim(),
        'ecoFriendly': _ecoFriendly,
        'fragancia': _fragancia,
        'cantidadAproximada': _cantidad,
        'metodoPago': metodoPago,
        'opcionAcabado': _opcionAcabado?.nombre,
        'precioAcabado': _opcionAcabado == null ? null : montoOpcionAcabado,
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
