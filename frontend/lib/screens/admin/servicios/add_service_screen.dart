import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/servicio.dart';
import '../../../models/servicio_display.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';

class _BeneficioFormItem {
  _BeneficioFormItem({this.icono = 'star', String titulo = '', String descripcion = ''})
    : tituloController = TextEditingController(text: titulo),
      descripcionController = TextEditingController(text: descripcion);

  factory _BeneficioFormItem.fromModelo(BeneficioServicio b) =>
      _BeneficioFormItem(icono: b.icono, titulo: b.titulo, descripcion: b.descripcion);

  String icono;
  final TextEditingController tituloController;
  final TextEditingController descripcionController;

  BeneficioServicio? toModelo() {
    final titulo = tituloController.text.trim();
    if (titulo.isEmpty) return null;
    return BeneficioServicio(icono: icono, titulo: titulo, descripcion: descripcionController.text.trim());
  }

  void dispose() {
    tituloController.dispose();
    descripcionController.dispose();
  }
}

class _OpcionFormItem {
  _OpcionFormItem({String nombre = '', double precioAdicional = 0, String descripcion = ''})
    : nombreController = TextEditingController(text: nombre),
      precioController = TextEditingController(text: precioAdicional == 0 ? '0' : precioAdicional.toString()),
      descripcionController = TextEditingController(text: descripcion);

  factory _OpcionFormItem.fromModelo(OpcionAcabado o) => _OpcionFormItem(
    nombre: o.nombre,
    precioAdicional: o.precioAdicional,
    descripcion: o.descripcion,
  );

  final TextEditingController nombreController;
  final TextEditingController precioController;
  final TextEditingController descripcionController;

  OpcionAcabado? toModelo() {
    final nombre = nombreController.text.trim();
    if (nombre.isEmpty) return null;
    return OpcionAcabado(
      nombre: nombre,
      precioAdicional: double.tryParse(precioController.text.trim()) ?? 0,
      descripcion: descripcionController.text.trim(),
    );
  }

  void dispose() {
    nombreController.dispose();
    precioController.dispose();
    descripcionController.dispose();
  }
}

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
  late final TextEditingController _comoFuncionaController;
  late final TextEditingController _tiempoEstimadoController;
  final _sugeridoController = TextEditingController();

  String _selectedUnit = 'kg';
  String _selectedIcon = 'local_laundry_service';
  final List<String> _sugeridos = [];
  final List<_BeneficioFormItem> _beneficios = [];
  final List<_OpcionFormItem> _opciones = [];

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
    _comoFuncionaController = TextEditingController(text: s?.comoFunciona ?? '');
    _tiempoEstimadoController = TextEditingController(text: s?.tiempoEstimado ?? '');
    if (s != null) {
      _selectedUnit = s.unidad;
      _selectedIcon = s.icono;
      _sugeridos.addAll(s.itemsSugeridos);
      _beneficios.addAll(s.beneficios.map(_BeneficioFormItem.fromModelo));
      _opciones.addAll(s.opcionesAcabado.map(_OpcionFormItem.fromModelo));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _comoFuncionaController.dispose();
    _tiempoEstimadoController.dispose();
    _sugeridoController.dispose();
    for (final b in _beneficios) {
      b.dispose();
    }
    for (final o in _opciones) {
      o.dispose();
    }
    super.dispose();
  }

  void _agregarSugerido() {
    final valor = _sugeridoController.text.trim();
    if (valor.isEmpty) return;
    setState(() {
      _sugeridos.add(valor);
      _sugeridoController.clear();
    });
  }

  void _agregarBeneficio() => setState(() => _beneficios.add(_BeneficioFormItem()));

  void _quitarBeneficio(int index) => setState(() => _beneficios.removeAt(index).dispose());

  void _agregarOpcion() => setState(() => _opciones.add(_OpcionFormItem()));

  void _quitarOpcion(int index) => setState(() => _opciones.removeAt(index).dispose());

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final servicio = Servicio(
      id: widget.servicio?.id ?? '',
      nombre: _nameController.text.trim(),
      icono: _selectedIcon,
      precio: double.tryParse(_priceController.text.trim()) ?? 0.0,
      unidad: _selectedUnit,
      descripcion: _descriptionController.text.trim(),
      activo: widget.servicio?.activo ?? true,
      comoFunciona: _comoFuncionaController.text.trim(),
      tiempoEstimado: _tiempoEstimadoController.text.trim(),
      itemsSugeridos: _sugeridos,
      beneficios: _beneficios.map((b) => b.toModelo()).nonNulls.toList(),
      opcionesAcabado: _opciones.map((o) => o.toModelo()).nonNulls.toList(),
    );
    final provider = context.read<AdminProvider>();

    try {
      if (widget.servicio == null) {
        await provider.addServicio(servicio);
      } else {
        await provider.updateServicio(servicio);
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

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
    filled: true,
    fillColor: AppColors.surfaceContainerLowest,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );

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
                _SeccionTitulo('Ícono del Servicio'),
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
                        onTap: () => setState(() => _selectedIcon = item.$1),
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

                _SeccionTitulo('Detalles del Servicio'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Ingresa el nombre del servicio' : null,
                  decoration: _decoration('Nombre del Servicio'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Ingresa el precio';
                          if (double.tryParse(value.trim()) == null) return 'Precio inválido';
                          return null;
                        },
                        decoration: _decoration('Precio (\$)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        isExpanded: true,
                        decoration: _decoration('Unidad'),
                        items: _units
                            .map((unit) => DropdownMenuItem<String>(value: unit, child: Text('/ $unit')))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedUnit = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Ingresa la descripción del servicio' : null,
                  decoration: _decoration('Descripción corta (la que ve el cliente en el catálogo)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tiempoEstimadoController,
                  decoration: _decoration('Tiempo estimado', hint: 'Ej. 24 horas, 12-24 horas'),
                ),
                const SizedBox(height: 32),

                _SeccionTitulo('Cómo funciona'),
                const SizedBox(height: 4),
                Text(
                  'Explicación larga que se muestra en la pantalla de detalle del servicio.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comoFuncionaController,
                  maxLines: 4,
                  decoration: _decoration('Explicación de cómo funciona (opcional)'),
                ),
                const SizedBox(height: 32),

                _SeccionTitulo('Prendas/artículos sugeridos'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sugeridoController,
                        decoration: _decoration('Ej. Trajes, Abrigos'),
                        onFieldSubmitted: (_) => _agregarSugerido(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: _agregarSugerido,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                if (_sugeridos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _sugeridos.length; i++)
                        Chip(
                          label: Text(_sugeridos[i]),
                          onDeleted: () => setState(() => _sugeridos.removeAt(i)),
                          backgroundColor: AppColors.surfaceContainerHigh,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SeccionTitulo('Beneficios'),
                    TextButton.icon(
                      onPressed: _agregarBeneficio,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_beneficios.isEmpty)
                  Text(
                    'Sin beneficios agregados todavía.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                for (var i = 0; i < _beneficios.length; i++) ...[
                  _BeneficioCard(
                    item: _beneficios[i],
                    onEliminar: () => _quitarBeneficio(i),
                    onIconoChanged: (valor) => setState(() => _beneficios[i].icono = valor),
                    decoration: _decoration,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _SeccionTitulo('Opciones de acabado / tarifas')),
                    TextButton.icon(
                      onPressed: _agregarOpcion,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Variantes que el cliente puede elegir con un cargo extra sobre el precio '
                  'base (ej. "Doblado en Gancho", modo de entrega, o niveles de tarifa como '
                  '"Premium"/"Luxury"). Deja precio 0 si no cuesta extra.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (_opciones.isEmpty)
                  Text(
                    'Sin opciones agregadas: el cliente no verá ningún selector para este servicio.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                for (var i = 0; i < _opciones.length; i++) ...[
                  _OpcionCard(
                    item: _opciones[i],
                    unidad: _selectedUnit,
                    onEliminar: () => _quitarOpcion(i),
                    decoration: _decoration,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 32),

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

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
    );
  }
}

class _BeneficioCard extends StatelessWidget {
  const _BeneficioCard({
    required this.item,
    required this.onEliminar,
    required this.onIconoChanged,
    required this.decoration,
  });

  final _BeneficioFormItem item;
  final VoidCallback onEliminar;
  final ValueChanged<String> onIconoChanged;
  final InputDecoration Function(String, {String? hint}) decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: item.icono,
                  isExpanded: true,
                  decoration: decoration('Ícono'),
                  items: beneficioIconos.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(e.value, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(e.key),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (valor) {
                    if (valor != null) onIconoChanged(valor);
                  },
                ),
              ),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(controller: item.tituloController, decoration: decoration('Título')),
          const SizedBox(height: 12),
          TextFormField(
            controller: item.descripcionController,
            maxLines: 2,
            decoration: decoration('Descripción'),
          ),
        ],
      ),
    );
  }
}

class _OpcionCard extends StatelessWidget {
  const _OpcionCard({
    required this.item,
    required this.unidad,
    required this.onEliminar,
    required this.decoration,
  });

  final _OpcionFormItem item;
  final String unidad;
  final VoidCallback onEliminar;
  final InputDecoration Function(String, {String? hint}) decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(controller: item.nombreController, decoration: decoration('Nombre')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: item.precioController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: decoration('+\$ / $unidad'),
                ),
              ),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: item.descripcionController,
            maxLines: 2,
            decoration: decoration('Descripción'),
          ),
        ],
      ),
    );
  }
}
