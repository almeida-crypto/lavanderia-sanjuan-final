import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/app_colors.dart';

class _Pregunta {
  const _Pregunta({required this.pregunta, required this.respuesta});

  final String pregunta;
  final String respuesta;
}

const _preguntasFrecuentes = [
  _Pregunta(
    pregunta: '¿Cómo cancelo un pedido?',
    respuesta:
        'Ve a "Mis Pedidos", abre el pedido activo y toca "Cancelar Pedido". Puedes cancelar sin cargo hasta 2 horas antes de la hora programada para la recolección.',
  ),
  _Pregunta(
    pregunta: '¿Cómo se calcula el precio final?',
    respuesta:
        'El total que ves al agendar es una referencia según la cantidad aproximada que indicas. El precio final se confirma cuando pesamos o verificamos tu pedido en la recolección, y lo verás actualizado en la factura.',
  ),
  _Pregunta(
    pregunta: '¿Puedo cambiar la dirección de recolección?',
    respuesta:
        'Sí, desde "Mi Perfil" → "Direcciones" puedes agregar, editar o elegir la dirección predeterminada para tus próximos pedidos.',
  ),
  _Pregunta(
    pregunta: '¿Qué hago si falta o llegó dañada una prenda?',
    respuesta:
        'Abre el pedido desde "Mis Pedidos" y usa la opción "Reportar un Problema". Nuestro equipo de soporte revisará el caso y te contactará.',
  ),
  _Pregunta(
    pregunta: '¿Cuánto tarda el servicio?',
    respuesta:
        'Depende del servicio, pero la mayoría de los pedidos de lavado y doblado se entregan el mismo día o al día siguiente de la recolección. Puedes ver el estado exacto en el seguimiento del pedido.',
  ),
];

class CentroAyudaScreen extends StatelessWidget {
  const CentroAyudaScreen({super.key});

  Future<void> _copiar(BuildContext context, String texto, String etiqueta) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$etiqueta copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Centro de Ayuda',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preguntas Frecuentes',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Column(
                    children: [
                      for (var i = 0; i < _preguntasFrecuentes.length; i++) ...[
                        if (i != 0) const Divider(height: 1, indent: 16, endIndent: 16),
                        ExpansionTile(
                          title: Text(
                            _preguntasFrecuentes[i].pregunta,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedAlignment: Alignment.centerLeft,
                          children: [
                            Text(
                              _preguntasFrecuentes[i].respuesta,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.4,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '¿Necesitas más ayuda?',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuestro equipo de soporte está disponible todos los días de 8:00 AM a 8:00 PM.',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    _ContactoTile(
                      icon: Icons.mail_outline_rounded,
                      label: 'soporte@freshclean.com',
                      onTap: () => _copiar(context, 'soporte@freshclean.com', 'Correo'),
                    ),
                    const SizedBox(height: 12),
                    _ContactoTile(
                      icon: Icons.call_outlined,
                      label: '+52 55 1234 5678',
                      onTap: () => _copiar(context, '+52 55 1234 5678', 'Teléfono'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactoTile extends StatelessWidget {
  const _ContactoTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
              ),
            ),
            const Icon(Icons.copy_rounded, color: AppColors.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}
