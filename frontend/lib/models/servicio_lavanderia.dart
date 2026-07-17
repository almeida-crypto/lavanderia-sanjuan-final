import 'package:flutter/material.dart';

enum TipoServicio { lavadoYPlegado, tintoreria, planchado, edredones }

class ServicioLavanderiaInfo {
  const ServicioLavanderiaInfo({
    required this.tipo,
    required this.nombre,
    required this.descripcion,
    required this.precioTexto,
    required this.totalEstimado,
    required this.unidad,
    required this.icon,
    this.destacado = false,
  });

  final TipoServicio tipo;
  final String nombre;
  final String descripcion;
  final String precioTexto;

  /// Precio de referencia por unidad (kg o pieza/prenda). El total real se
  /// confirma hasta que se pesa o cuenta el pedido en la recolección.
  final double totalEstimado;

  /// Unidad sobre la que aplica [totalEstimado], ej. 'kg' o 'prenda'.
  final String unidad;
  final IconData icon;
  final bool destacado;
}

const serviciosDisponibles = [
  ServicioLavanderiaInfo(
    tipo: TipoServicio.lavadoYPlegado,
    nombre: 'Lavado x Kilo',
    descripcion:
        'Nuestro servicio estándar de lavado, secado y doblado. Perfecto para tu ropa de todos los días.',
    precioTexto: 'Desde \$25/kg',
    totalEstimado: 25.00,
    unidad: 'kg',
    icon: Icons.local_laundry_service_rounded,
    destacado: true,
  ),
  ServicioLavanderiaInfo(
    tipo: TipoServicio.tintoreria,
    nombre: 'Tintorería',
    descripcion: 'Cuidado premium para telas delicadas.',
    precioTexto: 'Desde \$50/prenda',
    totalEstimado: 50.00,
    unidad: 'prenda',
    icon: Icons.checkroom_rounded,
  ),
  ServicioLavanderiaInfo(
    tipo: TipoServicio.planchado,
    nombre: 'Planchado',
    descripcion: 'Servicio de planchado profesional.',
    precioTexto: 'Desde \$15/prenda',
    totalEstimado: 15.00,
    unidad: 'prenda',
    icon: Icons.iron_rounded,
  ),
  ServicioLavanderiaInfo(
    tipo: TipoServicio.edredones,
    nombre: 'Edredones',
    descripcion: 'Limpieza profunda para blancos de cama de gran volumen.',
    precioTexto: 'Desde \$120/pieza',
    totalEstimado: 120.00,
    unidad: 'pieza',
    icon: Icons.bed_rounded,
  ),
];
