import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/promocion.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/imagen_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_image.dart';

class AddPromocionScreen extends StatefulWidget {
  const AddPromocionScreen({super.key, this.promocion});

  final Promocion? promocion;

  @override
  State<AddPromocionScreen> createState() => _AddPromocionScreenState();
}

class _AddPromocionScreenState extends State<AddPromocionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _descuentoController;
  late final TextEditingController _usosPorClienteController;
  late final TextEditingController _cantidadMinimaController;

  String? _servicioAplicable;
  late DateTime _fechaInicio;
  DateTime? _fechaFin;
  bool _activa = true;
  bool _isSaving = false;
  final _imagenService = ImagenService();
  String? _imagenUrl;
  bool _subiendoImagen = false;

  @override
  void initState() {
    super.initState();
    final p = widget.promocion;
    _codigoController = TextEditingController(text: p?.codigo ?? '');
    _tituloController = TextEditingController(text: p?.titulo ?? '');
    _descripcionController = TextEditingController(text: p?.descripcion ?? '');
    _descuentoController = TextEditingController(text: p?.descuentoPorcentaje.toStringAsFixed(0) ?? '');
    _usosPorClienteController = TextEditingController(text: p?.usosPorCliente?.toString() ?? '');
    _cantidadMinimaController = TextEditingController(text: p?.cantidadMinima?.toString() ?? '');
    _servicioAplicable = p?.servicioAplicable;
    _fechaInicio = p?.fechaInicio ?? DateTime.now();
    _fechaFin = p?.fechaFin;
    _activa = p?.activa ?? true;
    _imagenUrl = p?.imagenUrl;

    if (p == null) {
      context.read<AdminProvider>().cargarServicios();
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    _descuentoController.dispose();
    _usosPorClienteController.dispose();
    _cantidadMinimaController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final inicial = esInicio ? _fechaInicio : (_fechaFin ?? _fechaInicio.add(const Duration(days: 30)));
    final resultado = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (resultado == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = resultado;
      } else {
        _fechaFin = resultado;
      }
    });
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AdminProvider>();
    final nueva = Promocion(
      id: widget.promocion?.id ?? '',
      codigo: _codigoController.text.trim().toUpperCase(),
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      descuentoPorcentaje: double.tryParse(_descuentoController.text.trim()) ?? 0,
      servicioAplicable: _servicioAplicable,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      activa: _activa,
      usosPorCliente: int.tryParse(_usosPorClienteController.text.trim()),
      cantidadMinima: int.tryParse(_cantidadMinimaController.text.trim()),
      imagenUrl: _imagenUrl,
    );

    setState(() => _isSaving = true);
    try {
      if (widget.promocion == null) {
        await provider.addPromocion(nueva);
      } else {
        await provider.updatePromocion(nueva);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.promocion == null ? 'Promoción creada con éxito' : 'Promoción actualizada')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la promoción, revisa que el código no esté repetido')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _elegirImagen() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar una foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ]),
      ),
    );
    if (source == null) return;
    XFile? archivo;
    try {
      archivo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la cámara o la galería. Revisa los permisos de la aplicación.')),
        );
      }
      return;
    }
    if (archivo == null || !mounted) return;
    setState(() => _subiendoImagen = true);
    try {
      final url = await _imagenService.subir(archivo, carpeta: 'promociones');
      if (mounted) setState(() => _imagenUrl = url);
    } on ImagenException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la imagen. Verifica tu conexión e intenta nuevamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoImagen = false);
    }
  }

  String _formatoFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.promocion != null;
    final servicios = context.watch<AdminProvider>().servicios;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Editar Promoción' : 'Nueva Promoción',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: AppImage(
                      url: _imagenUrl,
                      fallbackAsset: 'assets/images/promocion_default.png',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _subiendoImagen ? null : _elegirImagen,
                  icon: _subiendoImagen
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_a_photo_outlined),
                  label: Text(_imagenUrl == null ? 'Agregar imagen' : 'Cambiar imagen'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Esto es lo que verá el cliente en Inicio y al agendar un pedido.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _codigoController,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Ingresa el código promocional' : null,
                  decoration: _decoration('Código (ej. FRESH20)'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _tituloController,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa un título' : null,
                  decoration: _decoration('Título (ej. 20% OFF en Tintorería)'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa una descripción' : null,
                  decoration: _decoration('Descripción'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descuentoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final n = double.tryParse((value ?? '').trim());
                    if (n == null) return 'Ingresa un número válido';
                    if (n < 0 || n > 100) return 'Debe estar entre 0 y 100';
                    return null;
                  },
                  decoration: _decoration('Descuento (%)'),
                ),
                const SizedBox(height: 16),

                Text(
                  'Condiciones (opcional)',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Déjalos vacíos para que el código no tenga límite de usos ni cantidad mínima.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _usosPorClienteController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final n = int.tryParse(value.trim());
                          if (n == null || n <= 0) return 'Debe ser mayor a 0';
                          return null;
                        },
                        decoration: _decoration('Usos por cliente'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cantidadMinimaController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final n = int.tryParse(value.trim());
                          if (n == null || n <= 0) return 'Debe ser mayor a 0';
                          return null;
                        },
                        decoration: _decoration('Mín. de prendas'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ej. "50% en más de 10 prendas" → Descuento 50, Mín. de prendas 10.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String?>(
                  // Se reconstruye cuando cambia el tamaño del catálogo para
                  // que, si esta pantalla se abre para editar antes de que
                  // termine de cargar, el valor inicial se re-aplique una
                  // vez que el servicio ya asignado exista entre los items.
                  key: ValueKey('servicio-dropdown-${servicios.length}'),
                  initialValue: servicios.any((s) => s.nombre == _servicioAplicable) ? _servicioAplicable : null,
                  isExpanded: true,
                  decoration: _decoration('Aplica a'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todos los servicios')),
                    for (final servicio in servicios)
                      DropdownMenuItem<String?>(value: servicio.nombre, child: Text(servicio.nombre)),
                  ],
                  onChanged: (value) => setState(() => _servicioAplicable = value),
                ),
                const SizedBox(height: 24),

                Text(
                  'Cuándo aplica',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FechaBoton(
                        etiqueta: 'Desde',
                        fecha: _formatoFecha(_fechaInicio),
                        onTap: () => _elegirFecha(esInicio: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FechaBoton(
                        etiqueta: 'Hasta (opcional)',
                        fecha: _fechaFin == null ? 'Sin fecha límite' : _formatoFecha(_fechaFin!),
                        onTap: () => _elegirFecha(esInicio: false),
                        onLimpiar: _fechaFin == null ? null : () => setState(() => _fechaFin = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _activa,
                  activeThumbColor: AppColors.primary,
                  title: Text('Activa', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Si la desactivas, el cliente no la verá aunque esté dentro de las fechas.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  onChanged: (value) => setState(() => _activa = value),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSaving ? null : () => _save(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEditing ? 'Guardar Cambios' : 'Crear Promoción',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
    filled: true,
    fillColor: AppColors.surfaceContainerLowest,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );
}

class _FechaBoton extends StatelessWidget {
  const _FechaBoton({required this.etiqueta, required this.fecha, required this.onTap, this.onLimpiar});

  final String etiqueta;
  final String fecha;
  final VoidCallback onTap;
  final VoidCallback? onLimpiar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  Text(
                    fecha,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onLimpiar != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: onLimpiar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
