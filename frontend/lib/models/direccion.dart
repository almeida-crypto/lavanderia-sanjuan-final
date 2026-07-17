import 'package:flutter/material.dart';

class Direccion {
  const Direccion({
    this.id,
    required this.icon,
    required this.titulo,
    required this.lineas,
    this.telefono,
    this.nota,
    this.predeterminada = false,
  });

  /// ID real asignado por el backend. Es null para una dirección armada
  /// localmente que todavía no se guardó (o no se pudo guardar) en la API.
  final String? id;
  final IconData icon;
  final String titulo;
  final List<String> lineas;
  final String? telefono;
  final String? nota;
  final bool predeterminada;

  factory Direccion.fromJson(Map<String, dynamic> json) => Direccion(
    id: json['id']?.toString(),
    icon: iconoParaEtiqueta(json['titulo']?.toString() ?? ''),
    titulo: json['titulo']?.toString() ?? 'Dirección',
    lineas: List<String>.from(json['lineas'] ?? []),
    telefono: json['telefono']?.toString(),
    nota: json['nota']?.toString(),
    predeterminada: json['predeterminada'] == true,
  );

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'lineas': lineas,
    'telefono': telefono,
    'nota': nota,
    'predeterminada': predeterminada,
  };

  Direccion copyWith({bool? predeterminada}) => Direccion(
    id: id,
    icon: icon,
    titulo: titulo,
    lineas: lineas,
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
