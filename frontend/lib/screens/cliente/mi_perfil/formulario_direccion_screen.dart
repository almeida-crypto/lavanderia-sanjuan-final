import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/direccion.dart';
import '../../../services/codigo_postal_service.dart';
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
  final _coloniaController = TextEditingController();
  final _entreCallesController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cpController = TextEditingController();
  final _codigoPostalService = CodigoPostalService();

  bool _buscandoCp = false;
  bool _cpValidado = false;
  String? _cpErrorMensaje;
  List<String> _coloniasSugeridas = [];

  bool get _esEdicion => widget.direccionExistente != null;

  @override
  void initState() {
    super.initState();
    final existente = widget.direccionExistente;
    if (existente != null) {
      _etiquetaController.text = existente.titulo;
      _calleController.text = existente.calle;
      _deptoController.text = existente.depto ?? '';
      _coloniaController.text = existente.colonia;
      _entreCallesController.text = existente.entreCalles ?? '';
      _ciudadController.text = existente.ciudad;
      _estadoController.text = existente.estado;
      _cpController.text = existente.codigoPostal;
      // La dirección ya fue guardada anteriormente; se vuelve a consultar si
      // el usuario modifica el código postal.
      _cpValidado = true;
    }
  }

  @override
  void dispose() {
    _etiquetaController.dispose();
    _calleController.dispose();
    _deptoController.dispose();
    _coloniaController.dispose();
    _entreCallesController.dispose();
    _ciudadController.dispose();
    _estadoController.dispose();
    _cpController.dispose();
    super.dispose();
  }

  String? _requerido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    return null;
  }

  /// Al completar los 5 dígitos, consulta el catálogo real de SEPOMEX:
  /// rellena Estado y Ciudad solos, sugiere las colonias reales de ese CP
  /// (casi siempre hay varias) y avisa si el código postal no existe.
  Future<void> _buscarCodigoPostal(String value) async {
    final cp = value.trim();
    if (cp.length != 5) {
      setState(() {
        _cpValidado = false;
        _cpErrorMensaje = null;
        _coloniasSugeridas = [];
      });
      return;
    }

    setState(() {
      _buscandoCp = true;
      _cpErrorMensaje = null;
    });
    try {
      final info = await _codigoPostalService.buscar(cp);
      if (!mounted) return;
      setState(() {
        _cpValidado = true;
        _estadoController.text = info.estado;
        _ciudadController.text = info.ciudad;
        _coloniasSugeridas = info.colonias;
        if (_coloniaController.text.trim().isEmpty && info.colonias.length == 1) {
          _coloniaController.text = info.colonias.first;
        }
      });
    } on CodigoPostalException catch (e) {
      if (!mounted) return;
      setState(() {
        _cpValidado = false;
        _cpErrorMensaje = e.message;
        _coloniasSugeridas = [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cpValidado = false;
        _cpErrorMensaje = 'No se pudo validar el código postal. Revisa tu conexión e inténtalo de nuevo.';
        _coloniasSugeridas = [];
      });
    } finally {
      if (mounted) setState(() => _buscandoCp = false);
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final direccion = Direccion(
      id: widget.direccionExistente?.id,
      icon: iconoParaEtiqueta(_etiquetaController.text.trim()),
      titulo: _etiquetaController.text.trim(),
      calle: _calleController.text.trim(),
      depto: _deptoController.text.trim(),
      colonia: _coloniaController.text.trim(),
      entreCalles: _entreCallesController.text.trim(),
      ciudad: _ciudadController.text.trim(),
      estado: _estadoController.text.trim(),
      codigoPostal: _cpController.text.trim(),
      telefono: widget.direccionExistente?.telefono,
      nota: widget.direccionExistente?.nota,
      predeterminada: widget.direccionExistente?.predeterminada ?? false,
    );

    Navigator.of(context).pop(direccion);
  }

  String? _validarCodigoPostal(String? value) {
    final cp = value?.trim() ?? '';
    if (cp.isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^\d{5}$').hasMatch(cp)) return 'Escribe los 5 dígitos';
    if (_buscandoCp) return 'Espera a que termine la validación';
    if (!_cpValidado) return _cpErrorMensaje ?? 'El código postal debe existir';
    return null;
  }

  String? _validarColonia(String? value) {
    final requerido = _requerido(value);
    if (requerido != null) return requerido;
    if (_coloniasSugeridas.isNotEmpty &&
        !_coloniasSugeridas.any((c) => c.toLowerCase() == value!.trim().toLowerCase())) {
      return 'Selecciona una colonia correspondiente a este código postal';
    }
    return null;
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
                      const SizedBox(height: 16),
                      _CampoDireccion(
                        label: 'Departamento, Piso, etc. (Opcional)',
                        controller: _deptoController,
                        hintText: 'Depto 4B',
                        icon: Icons.apartment_rounded,
                      ),
                      const SizedBox(height: 16),
                      _CampoDireccion(
                        label: 'Colonia',
                        controller: _coloniaController,
                        hintText: 'Ej. Centro',
                        icon: Icons.holiday_village_outlined,
                        validator: _validarColonia,
                      ),
                      if (_coloniasSugeridas.length > 1) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final colonia in _coloniasSugeridas)
                              _ColoniaChip(
                                label: colonia,
                                seleccionada: _coloniaController.text.trim() == colonia,
                                onTap: () => setState(() => _coloniaController.text = colonia),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      _CampoDireccion(
                        label: 'Entre calles / Referencias (Opcional)',
                        controller: _entreCallesController,
                        hintText: 'Ej. entre Av. Juárez y Calle 5, casa azul',
                        icon: Icons.explore_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _CampoDireccion(
                              label: 'Código Postal',
                              controller: _cpController,
                              hintText: '54000',
                              keyboardType: TextInputType.number,
                              validator: _validarCodigoPostal,
                              onChanged: _buscarCodigoPostal,
                              helperError: _cpErrorMensaje,
                              suffixIcon: _buscandoCp
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : (_cpErrorMensaje == null && _coloniasSugeridas.isNotEmpty
                                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                                      : null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _CampoDireccion(
                              label: 'Ciudad / Municipio',
                              controller: _ciudadController,
                              hintText: 'Tu ciudad',
                              icon: Icons.location_city_rounded,
                              validator: _requerido,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CampoDireccion(
                        label: 'Estado',
                        controller: _estadoController,
                        hintText: 'Ej. Jalisco',
                        icon: Icons.map_outlined,
                        validator: _requerido,
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

class _ColoniaChip extends StatelessWidget {
  const _ColoniaChip({required this.label, required this.seleccionada, required this.onTap});

  final String label;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: seleccionada ? AppColors.primary : AppColors.outlineVariant),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: seleccionada ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
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
    this.onChanged,
    this.suffixIcon,
    this.helperError,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  /// Mensaje de error "en vivo" (ej. "ese código postal no existe") que se
  /// muestra debajo del campo sin depender de que se intente enviar el
  /// formulario, a diferencia de [validator].
  final String? helperError;

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
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: AppColors.outline.withValues(alpha: 0.6)),
            prefixIcon: icon != null ? Icon(icon, color: AppColors.outline, size: 20) : null,
            suffixIcon: suffixIcon,
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
        if (helperError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              helperError!,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}
