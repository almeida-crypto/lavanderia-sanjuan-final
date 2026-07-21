import 'package:flutter/material.dart';
import '../models/opcion_catalogo.dart';
import '../models/pedido_admin.dart';
import '../models/promocion.dart';
import '../models/servicio.dart';
import '../models/usuario.dart';
import '../services/empleado_service.dart';
import '../services/opcion_catalogo_service.dart';
import '../services/pedido_service.dart';
import '../services/promocion_service.dart';
import '../services/servicio_service.dart';

class AdminProvider extends ChangeNotifier {
  final _pedidoService = PedidoService();
  final _servicioService = ServicioService();
  final _promocionService = PromocionService();
  final _opcionCatalogoService = OpcionCatalogoService();
  final _empleadoService = EmpleadoService();

  final List<PedidoAdmin> _pedidos = [];

  bool _isLoading = false;
  String? _error;

  List<PedidoAdmin> get pedidos => List.unmodifiable(_pedidos);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Gestión de empleados: respaldada por cuentas reales de Supabase Auth
  // (rol "empleado" o "administrador"), administradas por el admin desde su
  // perfil. Nunca se guarda una copia local: cada acción llama al backend y
  // luego refresca la lista para reflejar el estado real de la cuenta.

  final List<Usuario> _empleados = [];
  bool _isLoadingEmpleados = false;
  String? _errorEmpleados;

  List<Usuario> get empleados => List.unmodifiable(_empleados);
  bool get isLoadingEmpleados => _isLoadingEmpleados;
  String? get errorEmpleados => _errorEmpleados;

  Future<void> cargarEmpleados() async {
    _isLoadingEmpleados = true;
    _errorEmpleados = null;
    notifyListeners();
    try {
      final data = await _empleadoService.listar();
      _empleados
        ..clear()
        ..addAll(data);
    } catch (_) {
      _errorEmpleados = 'No se pudo cargar el personal';
    } finally {
      _isLoadingEmpleados = false;
      notifyListeners();
    }
  }

  Future<void> crearEmpleado({
    required String nombre,
    required String correo,
    required String password,
    required UserRole rol,
  }) async {
    final creado = await _empleadoService.crear(nombre: nombre, correo: correo, password: password, rol: rol);
    _empleados.add(creado);
    notifyListeners();
  }

  Future<void> cambiarRolEmpleado(String id, UserRole rol, {required String actorId}) async {
    final actualizado = await _empleadoService.cambiarRol(id, rol, actorId: actorId);
    final index = _empleados.indexWhere((e) => e.id == id);
    if (index != -1) {
      _empleados[index] = actualizado;
      notifyListeners();
    }
  }

  Future<void> cambiarEstadoEmpleado(String id, bool activa, {required String actorId}) async {
    final actualizado = await _empleadoService.cambiarEstado(id, activa, actorId: actorId);
    final index = _empleados.indexWhere((e) => e.id == id);
    if (index != -1) {
      _empleados[index] = actualizado;
      notifyListeners();
    }
  }

  Future<void> cambiarPasswordEmpleado(
    String id, {
    required String nuevaPassword,
    required String actorCorreo,
    required String actorPassword,
  }) async {
    await _empleadoService.cambiarPassword(
      id,
      nuevaPassword: nuevaPassword,
      actorCorreo: actorCorreo,
      actorPassword: actorPassword,
    );
  }

  Future<void> eliminarEmpleado(String id, {required String actorId}) async {
    await _empleadoService.eliminar(id, actorId: actorId);
    _empleados.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  bool esEmpleadoEmail(String email) {
    if (email.isEmpty) return false;
    final lower = email.trim().toLowerCase();
    return _empleados.any((e) => e.correo.trim().toLowerCase() == lower && (e.rol == UserRole.empleado || e.rol == UserRole.repartidor));
  }

  /// Limpia los datos de la sesión del admin/empleado saliente para que la
  /// próxima cuenta que inicie sesión en el dispositivo no vea (ni por un
  /// instante) pedidos o personal de la cuenta anterior.
  void limpiar() {
    _pedidos.clear();
    _empleados.clear();
    _error = null;
    _errorEmpleados = null;
    notifyListeners();
  }

  /// Trae los pedidos reales desde el backend (todos, sin filtrar por
  /// cliente, ya que este es el panel de administrador).
  Future<void> cargarPedidos() async {
    if (_isLoading) return;
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
    final creadoEn = DateTime.tryParse(json['createdAt']?.toString() ?? '');

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
      fragancia: json['fragancia']?.toString(),
      cantidadAproximada: int.tryParse(json['cantidadAproximada']?.toString() ?? ''),
      pesoConfirmado: double.tryParse(json['pesoConfirmado']?.toString() ?? ''),
      totalConfirmado: totalConfirmado,
      metodoPago: json['metodoPago']?.toString(),
      repartidorNombre: (repartidor == null || repartidor.isEmpty) ? null : repartidor,
      repartidorId: json['repartidorId']?.toString(),
      warningMessage: warningMessage,
      opcionAcabado: opcionAcabado,
      creadoEn: creadoEn,
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

  Future<void> asignarRepartidor(String pedidoId, Usuario repartidor) async {
    final actualizado = await _pedidoService.asignarRepartidor(
      pedidoId,
      repartidorId: repartidor.id,
    );
    final index = _pedidos.indexWhere((pedido) => pedido.id == pedidoId);
    if (index != -1) {
      _pedidos[index] = _mapPedido(actualizado);
      notifyListeners();
    }
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
      usosPorCliente: actual.usosPorCliente,
      cantidadMinima: actual.cantidadMinima,
      imagenUrl: actual.imagenUrl,
    );
    _promociones[index] = await _promocionService.actualizar(editada);
    notifyListeners();
  }

  // Catálogo global de opciones (ej. "Doblado en Gancho"): se definen una
  // sola vez aquí y cualquier servicio (actual o nuevo) puede ofrecerlas,
  // cada uno con su propio precio adicional.

  final List<OpcionCatalogo> _opcionesCatalogo = [];
  bool _isLoadingOpcionesCatalogo = false;

  List<OpcionCatalogo> get opcionesCatalogo => List.unmodifiable(_opcionesCatalogo);
  bool get isLoadingOpcionesCatalogo => _isLoadingOpcionesCatalogo;

  Future<void> cargarOpcionesCatalogo() async {
    _isLoadingOpcionesCatalogo = true;
    notifyListeners();
    try {
      final data = await _opcionCatalogoService.listar();
      _opcionesCatalogo
        ..clear()
        ..addAll(data);
    } catch (_) {
      // Conserva la lista previa para que la pantalla siga usable.
    } finally {
      _isLoadingOpcionesCatalogo = false;
      notifyListeners();
    }
  }

  Future<void> addOpcionCatalogo(OpcionCatalogo opcion) async {
    final guardada = await _opcionCatalogoService.crear(opcion);
    _opcionesCatalogo.add(guardada);
    notifyListeners();
  }

  Future<void> updateOpcionCatalogo(OpcionCatalogo opcion) async {
    final index = _opcionesCatalogo.indexWhere((o) => o.id == opcion.id);
    final actualizada = await _opcionCatalogoService.actualizar(opcion);
    if (index != -1) {
      _opcionesCatalogo[index] = actualizada;
      notifyListeners();
    }
  }

  Future<void> toggleOpcionCatalogoActiva(String id) async {
    final index = _opcionesCatalogo.indexWhere((o) => o.id == id);
    if (index == -1) return;
    final editada = _opcionesCatalogo[index].copyWith(activa: !_opcionesCatalogo[index].activa);
    _opcionesCatalogo[index] = await _opcionCatalogoService.actualizar(editada);
    notifyListeners();
  }
}
