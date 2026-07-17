import 'package:flutter/material.dart';
import '../models/pedido_admin.dart';
import '../models/promocion.dart';
import '../models/servicio.dart';
import '../services/pedido_service.dart';
import '../services/promocion_service.dart';
import '../services/servicio_service.dart';

class AdminProvider extends ChangeNotifier {
  final _pedidoService = PedidoService();
  final _servicioService = ServicioService();
  final _promocionService = PromocionService();

  final List<PedidoAdmin> _pedidos = [];
  bool _isLoading = false;
  String? _error;

  List<PedidoAdmin> get pedidos => List.unmodifiable(_pedidos);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Trae los pedidos reales desde el backend (todos, sin filtrar por
  /// cliente, ya que este es el panel de administrador).
  Future<void> cargarPedidos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _pedidoService.listarPedidos();
      _pedidos
        ..clear()
        ..addAll(data.map(_mapPedido));
      await cargarServicios();
    } catch (_) {
      _error = 'No se pudieron cargar los pedidos';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarServicios() async {
    try {
      final data = await _servicioService.listar();
      _servicios
        ..clear()
        ..addAll(data);
      notifyListeners();
    } catch (_) {
      // Conserva el catálogo inicial para que la interfaz siga siendo usable.
    }
  }

  PedidoAdmin _mapPedido(Map<String, dynamic> json) {
    final servicioNombre = json['servicio']?.toString() ?? 'Servicio';
    final total = double.tryParse(json['total']?.toString() ?? '0') ?? 0;
    final totalConfirmado = double.tryParse(json['totalConfirmado']?.toString() ?? '');
    final repartidor = json['repartidor']?.toString();
    final fecha = json['fecha']?.toString() ?? 'Sin fecha';
    final estado = pedidoEstadoFromString(json['estado']?.toString());

    final reporteTipo = json['reporteTipo']?.toString();
    final reporteDetalles = json['reporteDetalles']?.toString();
    final warningMessage = estado == PedidoEstado.atencion && (reporteTipo?.isNotEmpty ?? false)
        ? (reporteDetalles?.isNotEmpty ?? false ? '$reporteTipo: $reporteDetalles' : reporteTipo)
        : null;

    final razonCancelacion = json['razonCancelacion']?.toString();
    final comentariosCancelacion = json['comentariosCancelacion']?.toString();
    final calificacion = int.tryParse(json['calificacion']?.toString() ?? '');
    final resena = json['resena']?.toString();
    final opcionAcabado = json['opcionAcabado']?.toString();
    final precioAcabado = double.tryParse(json['precioAcabado']?.toString() ?? '');

    final notas = [NotaPedido(fecha: fecha, texto: 'Pedido recibido')];
    if (estado == PedidoEstado.cancelado && (razonCancelacion?.isNotEmpty ?? false)) {
      notas.add(NotaPedido(
        fecha: fecha,
        texto: (comentariosCancelacion?.isNotEmpty ?? false)
            ? 'Cliente canceló: $razonCancelacion — $comentariosCancelacion'
            : 'Cliente canceló: $razonCancelacion',
        autor: 'Cliente',
      ));
    }
    if (reporteTipo?.isNotEmpty ?? false) {
      notas.add(NotaPedido(
        fecha: fecha,
        texto: (reporteDetalles?.isNotEmpty ?? false)
            ? 'Reporte del cliente ($reporteTipo): $reporteDetalles'
            : 'Reporte del cliente: $reporteTipo',
        autor: 'Cliente',
      ));
    }
    if (calificacion != null) {
      notas.add(NotaPedido(
        fecha: fecha,
        texto: (resena?.isNotEmpty ?? false) ? 'Calificación: $calificacion★ — $resena' : 'Calificación: $calificacion★',
        autor: 'Cliente',
      ));
    }

    return PedidoAdmin(
      id: json['id']?.toString() ?? '',
      numeroOrden: int.tryParse(json['numeroOrden']?.toString() ?? '') ?? 0,
      clienteNombre: json['clienteNombre']?.toString() ?? 'Cliente',
      clienteEmail: json['clienteEmail']?.toString() ?? 'No especificado',
      clienteTelefono: json['clienteTelefono']?.toString() ?? 'No especificado',
      clienteDireccion: json['direccion']?.toString() ?? 'Sin dirección',
      servicioNombre: servicioNombre,
      servicioIcono: _iconoParaServicio(servicioNombre),
      tipoEntrega: 'Domicilio',
      estado: estado,
      progreso: _progresoParaEstado(estado),
      fecha: fecha,
      items: [
        // Si el cliente eligió una opción con cargo extra, se separa del
        // precio base para que el desglose sume el mismo total que se le
        // cobró (en vez de sumarlo dos veces).
        PedidoItem(nombre: servicioNombre, precio: (totalConfirmado ?? total) - (precioAcabado ?? 0)),
        if (opcionAcabado != null && opcionAcabado.isNotEmpty)
          PedidoItem(nombre: opcionAcabado, precio: precioAcabado ?? 0, descripcion: 'Opción elegida por el cliente'),
      ],
      notas: notas,
      ecoFriendly: json['ecoFriendly'] == true,
      fragancia: json['fragancia']?.toString(),
      cantidadAproximada: int.tryParse(json['cantidadAproximada']?.toString() ?? ''),
      pesoConfirmado: double.tryParse(json['pesoConfirmado']?.toString() ?? ''),
      totalConfirmado: totalConfirmado,
      metodoPago: json['metodoPago']?.toString(),
      repartidorNombre: (repartidor == null || repartidor.isEmpty) ? null : repartidor,
      warningMessage: warningMessage,
      opcionAcabado: opcionAcabado,
    );
  }

  String _iconoParaServicio(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('planch')) return 'iron';
    if (n.contains('tintorer')) return 'dry_cleaning';
    if (n.contains('edred')) return 'bed';
    if (n.contains('kilo') || n.contains('kg')) return 'scale';
    return 'local_laundry_service';
  }

  double _progresoParaEstado(PedidoEstado estado) {
    switch (estado) {
      case PedidoEstado.recibido:
        return 0.1;
      case PedidoEstado.asignado:
        return 0.3;
      case PedidoEstado.enPlanta:
        return 0.4;
      case PedidoEstado.lavando:
        return 0.6;
      case PedidoEstado.secandoDoblado:
        return 0.8;
      case PedidoEstado.enCamino:
        return 0.9;
      case PedidoEstado.listo:
      case PedidoEstado.entregado:
        return 1.0;
      case PedidoEstado.atencion:
      case PedidoEstado.cancelado:
        return 0.0;
    }
  }

  Future<void> updatePedidoEstado(String id, PedidoEstado nuevoEstado) async {
    final index = _pedidos.indexWhere((p) => p.id == id);
    if (index == -1) return;

    await _pedidoService.actualizarEstado(id, estadoToString(nuevoEstado));

    _pedidos[index].estado = nuevoEstado;
    _pedidos[index].progreso = _progresoParaEstado(nuevoEstado);
    _pedidos[index].notas.add(
      NotaPedido(fecha: 'Justo ahora', texto: "Estado cambiado a '${estadoToString(nuevoEstado)}'", autor: 'Admin'),
    );
    notifyListeners();
  }

  Future<void> assignRepartidor(String id, String repartidorNombre) async {
    final index = _pedidos.indexWhere((p) => p.id == id);
    if (index == -1) return;

    await _pedidoService.asignarRepartidor(id, repartidorNombre);

    _pedidos[index].repartidorNombre = repartidorNombre;
    if (_pedidos[index].estado == PedidoEstado.recibido) {
      _pedidos[index].estado = PedidoEstado.asignado;
      _pedidos[index].progreso = _progresoParaEstado(PedidoEstado.asignado);
    }
    _pedidos[index].notas.add(
      NotaPedido(fecha: 'Justo ahora', texto: 'Repartidor $repartidorNombre asignado', autor: 'Admin'),
    );
    notifyListeners();
  }

  /// Confirma el peso/cantidad real y el precio final tras pesar el pedido
  /// en planta, reemplazando el total estimado que se calculó al agendar.
  Future<void> confirmarPrecio(String id, {double? pesoConfirmado, required double totalConfirmado}) async {
    final index = _pedidos.indexWhere((p) => p.id == id);
    if (index == -1) return;

    await _pedidoService.confirmarPrecio(id, pesoConfirmado: pesoConfirmado, totalConfirmado: totalConfirmado);

    _pedidos[index].pesoConfirmado = pesoConfirmado;
    _pedidos[index].totalConfirmado = totalConfirmado;
    _pedidos[index].notas.add(
      NotaPedido(fecha: 'Justo ahora', texto: 'Precio final confirmado: \$${totalConfirmado.toStringAsFixed(2)}', autor: 'Admin'),
    );
    notifyListeners();
  }

  // Catálogo persistente. La lista inicial sirve solo mientras carga Supabase.

  final List<Servicio> _servicios = [
    Servicio(
      id: 'S-001',
      nombre: 'Lavado y Doblado',
      icono: 'local_laundry_service',
      precio: 1.50,
      unidad: 'kg',
      descripcion: 'Servicio estándar para ropa de uso diario. Incluye lavado, secado y doblado profesional.',
      activo: true,
    ),
    Servicio(
      id: 'S-002',
      nombre: 'Tintorería',
      icono: 'dry_cleaning',
      precio: 5.00,
      unidad: 'prenda',
      descripcion: 'Limpieza en seco para prendas delicadas, trajes, vestidos y ropa formal.',
      activo: true,
    ),
    Servicio(
      id: 'S-003',
      nombre: 'Planchado',
      icono: 'iron',
      precio: 1.00,
      unidad: 'prenda',
      descripcion: 'Planchado profesional para camisas, pantalones y prendas cotidianas.',
      activo: true,
    ),
    Servicio(
      id: 'S-004',
      nombre: 'Edredones',
      icono: 'bed',
      precio: 12.00,
      unidad: 'pieza',
      descripcion: 'Limpieza profunda para edredones, cobijas y ropa de cama de gran volumen.',
      activo: true,
    ),
  ];

  List<Servicio> get servicios => List.unmodifiable(_servicios);

  Future<void> addServicio(Servicio servicio) async {
    final guardado = await _servicioService.crear(servicio);
    _servicios.add(guardado);
    notifyListeners();
  }

  Future<void> updateServicio(Servicio servicio) async {
    final index = _servicios.indexWhere((s) => s.id == servicio.id);
    if (index != -1) {
      _servicios[index] = await _servicioService.actualizar(servicio);
      notifyListeners();
    }
  }

  Future<void> toggleServicioActivo(String id) async {
    final index = _servicios.indexWhere((s) => s.id == id);
    if (index != -1) {
      final editado = _servicios[index].copyWith(activo: !_servicios[index].activo);
      _servicios[index] = await _servicioService.actualizar(editado);
      notifyListeners();
    }
  }

  // Promociones: mismas reglas que ve/valida el cliente (código, vigencia,
  // servicio al que aplica), pero editables solo desde aquí.

  final List<Promocion> _promociones = [];
  bool _isLoadingPromociones = false;

  List<Promocion> get promociones => List.unmodifiable(_promociones);
  bool get isLoadingPromociones => _isLoadingPromociones;

  Future<void> cargarPromociones() async {
    _isLoadingPromociones = true;
    notifyListeners();
    try {
      final data = await _promocionService.listar();
      _promociones
        ..clear()
        ..addAll(data);
    } catch (_) {
      // Conserva la lista previa para que la pantalla siga usable.
    } finally {
      _isLoadingPromociones = false;
      notifyListeners();
    }
  }

  Future<void> addPromocion(Promocion promocion) async {
    final guardada = await _promocionService.crear(promocion);
    _promociones.insert(0, guardada);
    notifyListeners();
  }

  Future<void> updatePromocion(Promocion promocion) async {
    final index = _promociones.indexWhere((p) => p.id == promocion.id);
    final actualizada = await _promocionService.actualizar(promocion);
    if (index != -1) {
      _promociones[index] = actualizada;
      notifyListeners();
    }
  }

  Future<void> togglePromocionActiva(String id) async {
    final index = _promociones.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final actual = _promociones[index];
    final editada = Promocion(
      id: actual.id,
      codigo: actual.codigo,
      titulo: actual.titulo,
      descripcion: actual.descripcion,
      descuentoPorcentaje: actual.descuentoPorcentaje,
      servicioAplicable: actual.servicioAplicable,
      fechaInicio: actual.fechaInicio,
      fechaFin: actual.fechaFin,
      activa: !actual.activa,
    );
    _promociones[index] = await _promocionService.actualizar(editada);
    notifyListeners();
  }
}
