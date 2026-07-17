import 'package:flutter/material.dart';

import 'opcion_catalogo.dart';
import 'servicio.dart';
import 'servicio_lavanderia.dart';

TipoServicio tipoServicioDeNombre(String nombre) {
  final n = nombre.toLowerCase();
  if (n.contains('planch')) return TipoServicio.planchado;
  if (n.contains('tintorer')) return TipoServicio.tintoreria;
  if (n.contains('edred')) return TipoServicio.edredones;
  return TipoServicio.lavadoYPlegado;
}

ServicioLavanderiaInfo infoEstaticaParaTipo(TipoServicio tipo) =>
    serviciosDisponibles.firstWhere((s) => s.tipo == tipo, orElse: () => serviciosDisponibles.first);

/// Catálogo fijo de íconos que el admin puede elegir para un beneficio y que
/// el cliente sabe interpretar de vuelta (clave -> ícono real).
const beneficioIconos = <String, IconData>{
  'eco': Icons.eco_rounded,
  'sanitizer': Icons.sanitizer_rounded,
  'checkroom': Icons.checkroom_rounded,
  'schedule': Icons.schedule_rounded,
  'shipping': Icons.local_shipping_rounded,
  'shield': Icons.verified_user_rounded,
  'star': Icons.star_rounded,
  'inventory': Icons.inventory_2_rounded,
  'waves': Icons.waves_rounded,
  'iron': Icons.iron_rounded,
  'spa': Icons.spa_rounded,
};

IconData iconoDeBeneficio(String clave) => beneficioIconos[clave] ?? Icons.star_rounded;

/// Nombre en español de cada ícono, solo para mostrar en el selector del
/// admin (la clave en inglés se mantiene igual por dentro/en la base).
const beneficioIconoNombres = <String, String>{
  'eco': 'Ecológico',
  'sanitizer': 'Sanitizante',
  'checkroom': 'Prenda',
  'schedule': 'Horario',
  'shipping': 'Envío',
  'shield': 'Garantía',
  'star': 'Destacado',
  'inventory': 'Empaque',
  'waves': 'Suavidad',
  'iron': 'Planchado',
  'spa': 'Spa',
};

String nombreDeIconoBeneficio(String clave) => beneficioIconoNombres[clave] ?? clave;

/// Une el catálogo real del backend con la info de referencia estática
/// (usada solo mientras el catálogo real no ha cargado) en una sola forma,
/// para que las pantallas no necesiten saber de dónde vino el dato.
class ServicioDisplay {
  const ServicioDisplay({
    required this.tipo,
    required this.nombre,
    required this.descripcion,
    required this.precioTexto,
    required this.icon,
    required this.destacado,
  });

  factory ServicioDisplay.fromReal(Servicio servicio) {
    final tipo = tipoServicioDeNombre(servicio.nombre);
    return ServicioDisplay(
      tipo: tipo,
      nombre: servicio.nombre,
      descripcion: servicio.descripcion,
      precioTexto: 'Desde \$${servicio.precio.toStringAsFixed(2)}/${servicio.unidad}',
      icon: infoEstaticaParaTipo(tipo).icon,
      destacado: tipo == TipoServicio.lavadoYPlegado,
    );
  }

  factory ServicioDisplay.fromEstatico(ServicioLavanderiaInfo info) => ServicioDisplay(
    tipo: info.tipo,
    nombre: info.nombre,
    descripcion: info.descripcion,
    precioTexto: info.precioTexto,
    icon: info.icon,
    destacado: info.destacado,
  );

  final TipoServicio tipo;
  final String nombre;
  final String descripcion;
  final String precioTexto;
  final IconData icon;
  final bool destacado;
}

/// Catálogo listo para mostrar: usa el real si ya cargó (y tiene servicios
/// activos), si no cae al de referencia estático.
List<ServicioDisplay> catalogoParaMostrar(List<Servicio> activosReales) => activosReales.isNotEmpty
    ? activosReales.map(ServicioDisplay.fromReal).toList()
    : serviciosDisponibles.map(ServicioDisplay.fromEstatico).toList();

/// Convierte las referencias que guarda un servicio (opcionId + precio para
/// ESE servicio) en opciones listas para mostrar, resolviendo cada una
/// contra el catálogo global. Si una opción fue borrada del catálogo, se
/// omite en vez de mostrar una tarjeta rota.
List<OpcionAcabado> resolverOpcionesAcabado(
  List<OpcionAcabadoRef> referencias,
  List<OpcionCatalogo> catalogo,
) {
  final resultado = <OpcionAcabado>[];
  for (final ref in referencias) {
    OpcionCatalogo? opcion;
    for (final candidata in catalogo) {
      if (candidata.id == ref.opcionId) {
        opcion = candidata;
        break;
      }
    }
    if (opcion == null) continue;
    resultado.add(OpcionAcabado(
      nombre: opcion.nombre,
      descripcion: opcion.descripcion,
      precioAdicional: ref.precioAdicional,
    ));
  }
  return resultado;
}
