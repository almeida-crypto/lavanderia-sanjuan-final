import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/direccion.dart';
import '../../../utils/app_colors.dart';

class FormularioDireccionScreen extends StatefulWidget {
  const FormularioDireccionScreen({super.key, this.direccionExistente});

  /// Si viene una dirección, la pantalla funciona en modo edición
  /// (prellenada, título y botón distintos). Si es null, es modo alta.
  final Direccion? direccionExistente;

  @override
  State<FormularioDireccionScreen> createState() => _FormularioDireccionScreenState();
}

class _FormularioDireccionScreenState extends State<FormularioDireccionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _etiquetaController = TextEditingController();
  final _calleController = TextEditingController();
  final _deptoController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _cpController = TextEditingController();

  bool get _esEdicion => widget.direccionExistente != null;

  @override
  void initState() {
    super.initState();
    final existente = widget.direccionExistente;
    if (existente != null) {
      _etiquetaController.text = existente.titulo;
      _calleController.text = existente.lineas.isNotEmpty ? existente.lineas[0] : '';
      final segundaLinea = existente.lineas.length > 1 ? existente.lineas[1] : '';
      final partes = segundaLinea.split(', CP ');
      _ciudadController.text = partes.isNotEmpty ? partes[0] : '';
      _cpController.text = partes.length > 1 ? partes[1] : '';
    }
  }

  @override
  void dispose() {
    _etiquetaController.dispose();
    _calleController.dispose();
    _deptoController.dispose();
    _ciudadController.dispose();
    _cpController.dispose();
    super.dispose();
  }

  String? _requerido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    return null;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final calle = _calleController.text.trim();
    final depto = _deptoController.text.trim();
    final ciudad = _ciudadController.text.trim();
    final cp = _cpController.text.trim();

    final direccion = Direccion(
      id: widget.direccionExistente?.id,
      icon: iconoParaEtiqueta(_etiquetaController.text.trim()),
      titulo: _etiquetaController.text.trim(),
      lineas: [
        depto.isEmpty ? calle : '$calle, $depto',
        '$ciudad, CP $cp',
      ],
      telefono: widget.direccionExistente?.telefono,
      nota: widget.direccionExistente?.nota,
      predeterminada: widget.direccionExistente?.predeterminada ?? false,
    );

    Navigator.of(context).pop(direccion);
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurfaceVariant),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          _esEdicion ? 'Editar Dirección' : 'Añadir Nueva Dirección',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MapaPlaceholder(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_esEdicion) ...[
                        Text(
                          'Detalles de la Dirección',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ingresa la ubicación exacta para tus servicios de FreshClean.',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _CampoDireccion(
                        label: 'Etiqueta de la Dirección',
                        controller: _etiquetaController,
                        hintText: 'Ej. Casa, Oficina',
                        icon: Icons.label_outline_rounded,
                        validator: _requerido,
                      ),
                      const SizedBox(height: 16),
                      _CampoDireccion(
                        label: 'Calle y Número',
                        controller: _calleController,
                        hintText: 'Calle Principal 123',
                        icon: Icons.signpost_outlined,
                        validator: _requerido,
                      ),
                      if (!_esEdicion) ...[
                        const SizedBox(height: 16),
                        _CampoDireccion(
                          label: 'Departamento, Piso, etc. (Opcional)',
                          controller: _deptoController,
                          hintText: 'Depto 4B',
                          icon: Icons.apartment_rounded,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _CampoDireccion(
                              label: 'Ciudad',
                              controller: _ciudadController,
                              hintText: 'Tu ciudad',
                              icon: Icons.location_city_rounded,
                              validator: _requerido,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CampoDireccion(
                              label: 'Código Postal',
                              controller: _cpController,
                              hintText: '54000',
                              keyboardType: TextInputType.number,
                              validator: _requerido,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: ElevatedButton.icon(
            onPressed: _guardar,
            icon: Icon(_esEdicion ? Icons.save_rounded : Icons.check_circle_rounded, size: 20),
            label: Text(
              _esEdicion ? 'Guardar Cambios' : 'Guardar Dirección',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapaPlaceholder extends StatelessWidget {
  const _MapaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      color: AppColors.surfaceContainerLow,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.map_rounded, size: 96, color: AppColors.primary.withValues(alpha: 0.15)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12),
                  ],
                ),
                child: const Icon(Icons.location_on_rounded, color: Colors.white),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 12,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                ],
              ),
              child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoDireccion extends StatelessWidget {
  const _CampoDireccion({
    required this.label,
    required this.controller,
    required this.hintText,
    this.icon,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: AppColors.outline.withValues(alpha: 0.6)),
            prefixIcon: icon != null ? Icon(icon, color: AppColors.outline, size: 20) : null,
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
