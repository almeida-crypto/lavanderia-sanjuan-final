import 'package:flutter/material.dart';
import '../models/pedido_admin.dart';
import '../models/servicio.dart';
import '../services/pedido_service.dart';
import '../services/servicio_service.dart';

class AdminProvider extends ChangeNotifier {
  final _pedidoService = PedidoService();
  final _servicioService = ServicioService();

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

    return PedidoAdmin(
      id: json['id']?.toString() ?? '',
      clienteNombre: json['clienteNombre']?.toString() ?? 'Cliente',
      clienteEmail: json['clienteEmail']?.toString() ?? 'No especificado',
      clienteTelefono: json['clienteTelefono']?.toString() ?? 'No especificado',
      clienteDireccion: json['direccion']?.toString() ?? 'Sin dirección',
      servicioNombre: servicioNombre,
      servicioIcono: _iconoParaServicio(servicioNombre),
      tipoEntrega: 'Domicilio',
      estado: pedidoEstadoFromString(json['estado']?.toString()),
      progreso: _progresoParaEstado(pedidoEstadoFromString(json['estado']?.toString())),
      fecha: fecha,
      items: [PedidoItem(nombre: servicioNombre, precio: totalConfirmado ?? total)],
      notas: [NotaPedido(fecha: fecha, texto: 'Pedido recibido')],
      ecoFriendly: json['ecoFriendly'] == true,
      fragancia: json['fragancia']?.toString(),
      cantidadAproximada: int.tryParse(json['cantidadAproximada']?.toString() ?? ''),
      pesoConfirmado: double.tryParse(json['pesoConfirmado']?.toString() ?? ''),
      totalConfirmado: totalConfirmado,
      metodoPago: json['metodoPago']?.toString(),
      repartidorNombre: (repartidor == null || repartidor.isEmpty) ? null : repartidor,
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

  Future<void> updateServicio(
    String id, {
    String? nombre,
    String? icono,
    double? precio,
    String? unidad,
    String? descripcion,
    bool? activo,
  }) async {
    final index = _servicios.indexWhere((s) => s.id == id);
    if (index != -1) {
      final actual = _servicios[index];
      final editado = Servicio(
        id: actual.id,
        nombre: nombre ?? actual.nombre,
        icono: icono ?? actual.icono,
        precio: precio ?? actual.precio,
        unidad: unidad ?? actual.unidad,
        descripcion: descripcion ?? actual.descripcion,
        activo: activo ?? actual.activo,
      );
      _servicios[index] = await _servicioService.actualizar(editado);
      notifyListeners();
    }
  }

  Future<void> toggleServicioActivo(String id) async {
    final index = _servicios.indexWhere((s) => s.id == id);
    if (index != -1) {
      final actual = _servicios[index];
      final editado = Servicio(
        id: actual.id,
        nombre: actual.nombre,
        icono: actual.icono,
        precio: actual.precio,
        unidad: actual.unidad,
        descripcion: actual.descripcion,
        activo: !actual.activo,
      );
      _servicios[index] = await _servicioService.actualizar(editado);
      notifyListeners();
    }
  }
}
