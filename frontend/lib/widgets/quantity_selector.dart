import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

/// Selector de cantidad aproximada (kg, piezas, etc.) reutilizado en las
/// pantallas de servicio. Es solo una referencia para estimar el precio:
/// el total real se confirma al pesar/verificar el pedido en la recolección.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.label,
    required this.cantidad,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  final String label;
  final int cantidad;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                bg: AppColors.surfaceVariant,
                iconColor: AppColors.primary,
                onTap: onDecrementar,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$cantidad',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                bg: AppColors.primary,
                iconColor: Colors.white,
                onTap: onIncrementar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
