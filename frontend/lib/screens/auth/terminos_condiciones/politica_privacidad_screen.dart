import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/app_colors.dart';

class _Seccion {
  const _Seccion({required this.titulo, required this.contenido});

  final String titulo;
  final String contenido;
}

const _secciones = [
  _Seccion(
    titulo: '1. Información que Recopilamos',
    contenido:
        'Recopilamos los datos que nos proporcionas al crear tu cuenta (nombre, correo, teléfono), tus direcciones de recolección y entrega, tus métodos de pago guardados, y los detalles de cada pedido que realizas (servicio, fecha, preferencias como fragancia o eco-friendly).',
  ),
  _Seccion(
    titulo: '2. Uso de tu Información',
    contenido:
        'Usamos tus datos únicamente para operar el servicio: coordinar recolecciones y entregas, procesar pagos, confirmar el precio final de tus pedidos, y contactarte sobre el estado de tu servicio o problemas reportados.',
  ),
  _Seccion(
    titulo: '3. Con Quién Compartimos tu Información',
    contenido:
        'Compartimos la información estrictamente necesaria con nuestro personal operativo (planta y repartidores) para completar tu pedido. No vendemos ni compartimos tus datos personales con terceros para fines de mercadotecnia.',
  ),
  _Seccion(
    titulo: '4. Seguridad',
    contenido:
        'Protegemos tu información con medidas de seguridad razonables. Los datos de tus tarjetas se almacenan de forma segura y nunca se muestran completos dentro de la aplicación.',
  ),
  _Seccion(
    titulo: '5. Tus Derechos',
    contenido:
        'Puedes revisar y actualizar tu información personal en cualquier momento desde "Mi Perfil". Si deseas eliminar tu cuenta o tus datos, contáctanos desde el Centro de Ayuda.',
  ),
];

class PoliticaPrivacidadScreen extends StatelessWidget {
  const PoliticaPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Política de Privacidad',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceContainerHigh),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última actualización: 1 de Julio de 2026',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Text(
                  'En FreshClean respetamos tu privacidad. Esta política explica qué información recopilamos y cómo la usamos.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.onSurface,
                  ),
                ),
                for (final seccion in _secciones) ...[
                  const SizedBox(height: 24),
                  Text(
                    seccion.titulo,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    seccion.contenido,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
