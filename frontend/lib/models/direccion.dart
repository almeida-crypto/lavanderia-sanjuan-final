import 'package:flutter/material.dart';

class Direccion {
  const Direccion({
    this.id,
    required this.icon,
    required this.titulo,
    required this.calle,
    this.depto,
    required this.colonia,
    this.entreCalles,
    required this.ciudad,
    required this.estado,
    required this.codigoPostal,
    this.telefono,
    this.nota,
    this.predeterminada = false,
  });

  /// ID real asignado por el backend. Es null para una dirección armada
  /// localmente que todavía no se guardó (o no se pudo guardar) en la API.
  final String? id;
  final IconData icon;
  final String titulo;
  final String calle;
  final String? depto;
  final String colonia;

  /// Entre qué calles está o una referencia para encontrarla (ej. "frente al
  /// parque"), para que el repartidor la ubique aunque no haya numeración
  /// clara. Opcional porque no todas las direcciones lo necesitan.
  final String? entreCalles;
  final String ciudad;
  final String estado;
  final String codigoPostal;
  final String? telefono;
  final String? nota;
  final bool predeterminada;

  /// Líneas listas para mostrar en las pantallas que solo necesitan el
  /// texto de la dirección (tarjetas, resúmenes, tickets), armadas a partir
  /// de los campos reales en vez de que cada pantalla arme el texto.
  List<String> get lineas {
    final calleCompleta = (depto == null || depto!.isEmpty) ? calle : '$calle, $depto';
    final principal = colonia.isEmpty ? calleCompleta : '$calleCompleta, Col. $colonia';
    final resultado = <String>[principal];
    if (entreCalles != null && entreCalles!.isNotEmpty) {
      resultado.add('Entre calles: $entreCalles');
    }
    resultado.add('$ciudad, $estado, CP $codigoPostal');
    return resultado;
  }

  factory Direccion.fromJson(Map<String, dynamic> json) => Direccion(
    id: json['id']?.toString(),
    icon: iconoParaEtiqueta(json['titulo']?.toString() ?? ''),
    titulo: json['titulo']?.toString() ?? 'Dirección',
    calle: json['calle']?.toString() ?? '',
    depto: json['depto']?.toString(),
    colonia: json['colonia']?.toString() ?? '',
    entreCalles: json['entreCalles']?.toString(),
    ciudad: json['ciudad']?.toString() ?? '',
    estado: json['estado']?.toString() ?? '',
    codigoPostal: json['codigoPostal']?.toString() ?? '',
    telefono: json['telefono']?.toString(),
    nota: json['nota']?.toString(),
    predeterminada: json['predeterminada'] == true,
  );

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'calle': calle,
    'depto': depto,
    'colonia': colonia,
    'entreCalles': entreCalles,
    'ciudad': ciudad,
    'estado': estado,
    'codigoPostal': codigoPostal,
    'telefono': telefono,
    'nota': nota,
    'predeterminada': predeterminada,
  };

  Direccion copyWith({bool? predeterminada}) => Direccion(
    id: id,
    icon: icon,
    titulo: titulo,
    calle: calle,
    depto: depto,
    colonia: colonia,
    entreCalles: entreCalles,
    ciudad: ciudad,
    estado: estado,
    codigoPostal: codigoPostal,
    telefono: telefono,
    nota: nota,
    predeterminada: predeterminada ?? this.predeterminada,
  );
}

IconData iconoParaEtiqueta(String etiqueta) {
  final valor = etiqueta.toLowerCase();
  if (valor.contains('casa') || valor.contains('home')) return Icons.home_rounded;
  if (valor.contains('oficina') || valor.contains('office')) return Icons.business_rounded;
  return Icons.location_on_rounded;
}
