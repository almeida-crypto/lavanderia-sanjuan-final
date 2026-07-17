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
    titulo: '1. Uso del Servicio',
    contenido:
        'FreshClean proporciona un servicio de lavandería bajo demanda. El usuario se compromete a proporcionar información veraz y actualizada al registrarse. El uso de la plataforma está destinado exclusivamente a fines personales y no comerciales. Nos reservamos el derecho de denegar el servicio si consideramos que hay un uso indebido.',
  ),
  _Seccion(
    titulo: '2. Precios y Pagos',
    contenido:
        'Todos los precios de los servicios están indicados en la aplicación y pueden estar sujetos a cambios con previo aviso. El pago se procesará automáticamente a través del método de pago asociado a la cuenta del usuario una vez que el pedido haya sido completado o recolectado, según la política aplicable.',
  ),
  _Seccion(
    titulo: '3. Responsabilidades',
    contenido:
        'FreshClean se esfuerza por manejar todas las prendas con el mayor cuidado posible. Sin embargo, no nos hacemos responsables por artículos que se decoloren, encojan o sufran daños que sean inherentes al proceso de lavado normal o debido a defectos previos no reportados. En caso de pérdida o daño comprobable por negligencia nuestra, la compensación se limitará al valor depreciado de la prenda.',
  ),
  _Seccion(
    titulo: '4. Política de Cancelación',
    contenido:
        'Puedes cancelar tu pedido sin cargo hasta 2 horas antes de la hora programada para la recolección. Las cancelaciones realizadas fuera de este plazo pueden estar sujetas a una tarifa administrativa.',
  ),
  _Seccion(
    titulo: '5. Privacidad',
    contenido:
        'La recopilación y el uso de la información personal están regidos por nuestra Política de Privacidad, la cual forma parte integral de estos Términos y Condiciones.',
  ),
];

class TerminosCondicionesScreen extends StatelessWidget {
  const TerminosCondicionesScreen({super.key});

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
          'Términos y Condiciones',
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
                  'Por favor, lee detenidamente estos términos y condiciones antes de utilizar el servicio de FreshClean. Al acceder y utilizar nuestra plataforma, aceptas estar sujeto a estas condiciones.',
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
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'Acepto los Términos',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
