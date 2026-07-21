/// Un beneficio/ventaja que el admin describe para un servicio, mostrado
/// en la pantalla de detalle de ese servicio para el cliente.
class BeneficioServicio {
  const BeneficioServicio({required this.icono, required this.titulo, required this.descripcion});

  final String icono;
  final String titulo;
  final String descripcion;

  factory BeneficioServicio.fromJson(Map<String, dynamic> json) => BeneficioServicio(
    icono: json['icono']?.toString() ?? 'star',
    titulo: json['titulo']?.toString() ?? '',
    descripcion: json['descripcion']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'icono': icono, 'titulo': titulo, 'descripcion': descripcion};
}

/// Una opción de acabado/entrega YA RESUELTA contra el catálogo global (ej.
/// "Doblado en Gancho", o para Tintorería un nivel "Premium"), lista para
/// mostrar: nombre/descripción reales + el cargo adicional que le
/// corresponde al servicio desde el que se resolvió.
class OpcionAcabado {
  const OpcionAcabado({required this.nombre, required this.precioAdicional, this.descripcion = ''});

  final String nombre;
  final double precioAdicional;
  final String descripcion;
}

/// Lo que un servicio realmente guarda: una referencia a una fila del
/// catálogo global de opciones (ver OpcionCatalogo) más el cargo adicional
/// que le corresponde a ESTE servicio en particular. La misma opción
/// ("Doblado") puede costar distinto —o nada— según el servicio.
class OpcionAcabadoRef {
  const OpcionAcabadoRef({required this.opcionId, required this.precioAdicional});

  final String opcionId;
  final double precioAdicional;

  factory OpcionAcabadoRef.fromJson(Map<String, dynamic> json) => OpcionAcabadoRef(
    opcionId: json['opcionId']?.toString() ?? '',
    precioAdicional: double.tryParse(json['precioAdicional']?.toString() ?? '0') ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'opcionId': opcionId,
    'precioAdicional': precioAdicional,
  };
}

class Servicio {
  Servicio({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.precio,
    required this.unidad,
    required this.descripcion,
    this.activo = true,
    this.comoFunciona = '',
    this.tiempoEstimado = '',
    List<String>? itemsSugeridos,
    List<BeneficioServicio>? beneficios,
    List<OpcionAcabadoRef>? opcionesAcabado,
  }) : itemsSugeridos = itemsSugeridos ?? [],
       beneficios = beneficios ?? [],
       opcionesAcabado = opcionesAcabado ?? [];

  final String id;
  String nombre;
  String icono;
  double precio;
  String unidad;
  String descripcion;
  bool activo;

  /// Explicación de cómo funciona el servicio (el texto largo que antes
  /// estaba fijo en cada pantalla de detalle).
  String comoFunciona;

  /// Ej. "24 horas", "12-24 horas". Texto libre porque cada servicio lo
  /// expresa distinto.
  String tiempoEstimado;

  /// Prendas/artículos sugeridos para este servicio (chips informativos).
  List<String> itemsSugeridos;
  List<BeneficioServicio> beneficios;

  /// Referencias al catálogo global de opciones (ver OpcionCatalogo) que
  /// este servicio ofrece, cada una con el cargo adicional que le
  /// corresponde a este servicio en particular. Vacía = el servicio no
  /// ofrece variantes, se cobra el precio base tal cual.
  List<OpcionAcabadoRef> opcionesAcabado;

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? 'Servicio',
    icono: json['icono']?.toString() ?? 'local_laundry_service',
    precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
    unidad: json['unidad']?.toString() ?? 'kg',
    descripcion: json['descripcion']?.toString() ?? '',
    activo: json['activo'] != false,
    comoFunciona: json['comoFunciona']?.toString() ?? '',
    tiempoEstimado: json['tiempoEstimado']?.toString() ?? '',
    itemsSugeridos: (json['itemsSugeridos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    beneficios: (json['beneficios'] as List<dynamic>?)
            ?.map((e) => BeneficioServicio.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    opcionesAcabado: (json['opcionesAcabado'] as List<dynamic>?)
            ?.map((e) => OpcionAcabadoRef.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'icono': icono,
    'precio': precio,
    'unidad': unidad,
    'descripcion': descripcion,
    'activo': activo,
    'comoFunciona': comoFunciona,
    'tiempoEstimado': tiempoEstimado,
    'itemsSugeridos': itemsSugeridos,
    'beneficios': beneficios.map((b) => b.toJson()).toList(),
    'opcionesAcabado': opcionesAcabado.map((o) => o.toJson()).toList(),
  };

  /// Copia el servicio cambiando solo lo indicado; evita que guardar un
  /// cambio puntual (ej. activo/inactivo) borre sin querer el resto del
  /// contenido (beneficios, opciones de acabado, etc.).
  Servicio copyWith({
    String? nombre,
    String? icono,
    double? precio,
    String? unidad,
    String? descripcion,
    bool? activo,
    String? comoFunciona,
    String? tiempoEstimado,
    List<String>? itemsSugeridos,
    List<BeneficioServicio>? beneficios,
    List<OpcionAcabadoRef>? opcionesAcabado,
  }) => Servicio(
    id: id,
    nombre: nombre ?? this.nombre,
    icono: icono ?? this.icono,
    precio: precio ?? this.precio,
    unidad: unidad ?? this.unidad,
    descripcion: descripcion ?? this.descripcion,
    activo: activo ?? this.activo,
    comoFunciona: comoFunciona ?? this.comoFunciona,
    tiempoEstimado: tiempoEstimado ?? this.tiempoEstimado,
    itemsSugeridos: itemsSugeridos ?? this.itemsSugeridos,
    beneficios: beneficios ?? this.beneficios,
    opcionesAcabado: opcionesAcabado ?? this.opcionesAcabado,
  );
}
