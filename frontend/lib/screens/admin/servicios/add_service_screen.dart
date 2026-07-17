import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/servicio.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key, this.servicio});

  final Servicio? servicio;

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  String _selectedUnit = 'kg';
  String _selectedIcon = 'local_laundry_service';

  final List<String> _units = ['kg', 'prenda', 'pieza'];
  final List<(String, IconData)> _availableIcons = [
    ('local_laundry_service', Icons.local_laundry_service_rounded),
    ('dry_cleaning', Icons.dry_cleaning_outlined),
    ('iron', Icons.iron_outlined),
    ('bed', Icons.bed_outlined),
    ('scale', Icons.scale_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.servicio;
    _nameController = TextEditingController(text: s?.nombre ?? '');
    _priceController = TextEditingController(text: s?.precio.toStringAsFixed(2) ?? '');
    _descriptionController = TextEditingController(text: s?.descripcion ?? '');
    if (s != null) {
      _selectedUnit = s.unidad;
      _selectedIcon = s.icono;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final description = _descriptionController.text.trim();
    final provider = context.read<AdminProvider>();

    try {
      if (widget.servicio == null) {
        final newService = Servicio(
          id: '',
          nombre: name,
          icono: _selectedIcon,
          precio: price,
          unidad: _selectedUnit,
          descripcion: description,
          activo: true,
        );
        await provider.addServicio(newService);
      } else {
        await provider.updateServicio(
          widget.servicio!.id,
          nombre: name,
          icono: _selectedIcon,
          precio: price,
          unidad: _selectedUnit,
          descripcion: description,
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.servicio == null
            ? 'Nuevo servicio creado con éxito'
            : 'Servicio actualizado con éxito')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el servicio')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.servicio != null;

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
          isEditing ? 'Editar Servicio' : 'Nuevo Servicio',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
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
                // Icon Selection Row
                Text(
                  'Ícono del Servicio',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _availableIcons.map((item) {
                      final isSelected = _selectedIcon == item.$1;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIcon = item.$1;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            item.$2,
                            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Text fields
                Text(
                  'Detalles del Servicio',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre del servicio';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Nombre del Servicio',
                    labelStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Price and Unit Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el precio';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Precio inválido';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Precio (\$)',
                          labelStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                          filled: true,
                          fillColor: AppColors.surfaceContainerLowest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Unidad',
                          labelStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                          filled: true,
                          fillColor: AppColors.surfaceContainerLowest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text('/ $unit', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUnit = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la descripción del servicio';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Descripción del Servicio',
                    labelStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: () => _save(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isEditing ? 'Guardar Cambios' : 'Crear Servicio',
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
}
