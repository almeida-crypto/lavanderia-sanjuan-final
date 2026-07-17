import 'package:flutter/material.dart';

enum FranjaHoraria { manana, tarde, noche }

class FranjaHorariaInfo {
  const FranjaHorariaInfo({
    required this.valor,
    required this.etiqueta,
    required this.horario,
    required this.icon,
  });

  final FranjaHoraria valor;
  final String etiqueta;
  final String horario;
  final IconData icon;
}

const franjasDisponibles = [
  FranjaHorariaInfo(
    valor: FranjaHoraria.manana,
    etiqueta: 'Mañana',
    horario: '08:00 - 12:00',
    icon: Icons.light_mode_rounded,
  ),
  FranjaHorariaInfo(
    valor: FranjaHoraria.tarde,
    etiqueta: 'Tarde',
    horario: '13:00 - 17:00',
    icon: Icons.wb_sunny_rounded,
  ),
  FranjaHorariaInfo(
    valor: FranjaHoraria.noche,
    etiqueta: 'Noche',
    horario: '18:00 - 21:00',
    icon: Icons.dark_mode_rounded,
  ),
];
