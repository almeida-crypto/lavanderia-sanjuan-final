import 'package:flutter/material.dart';

class Fragancia {
  const Fragancia({required this.icon, required this.nombre, required this.descripcion});

  final IconData icon;
  final String nombre;
  final String descripcion;
}

const fraganciasDisponibles = [
  Fragancia(
    icon: Icons.spa_outlined,
    nombre: 'Lavanda',
    descripcion: 'Aroma floral suave, ideal para ropa de cama.',
  ),
  Fragancia(
    icon: Icons.local_florist_outlined,
    nombre: 'Cítrico',
    descripcion: 'Fresco y energizante, perfecto para uso diario.',
  ),
  Fragancia(
    icon: Icons.air_rounded,
    nombre: 'Brisa de Algodón',
    descripcion: 'Aroma limpio y ligero, discreto en cualquier prenda.',
  ),
  Fragancia(
    icon: Icons.eco_outlined,
    nombre: 'Menta Fresca',
    descripcion: 'Notas herbales suaves, muy duradero.',
  ),
  Fragancia(
    icon: Icons.do_not_disturb_alt_outlined,
    nombre: 'Sin Fragancia',
    descripcion: 'Sin aromas añadidos, ideal para pieles sensibles.',
  ),
];
