import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/imagen_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/app_image.dart';
import '../../../widgets/labeled_text_field.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoController;
  final _imagenService = ImagenService();
  String? _fotoUrl;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AuthProvider>().currentUser;
    _nombreController = TextEditingController(text: usuario?.nombre ?? '');
    _correoController = TextEditingController(text: usuario?.correo ?? '');
    _telefonoController = TextEditingController(text: usuario?.telefono ?? '');
    _fotoUrl = usuario?.fotoUrl;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre';
    return null;
  }

  String? _validarCorreo(String? value) {
    final correo = value?.trim() ?? '';
    if (correo.isEmpty) return 'Ingresa tu correo';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(correo)) return 'Correo inválido';
    return null;
  }

  String? _validarTelefono(String? value) {
    final telefono = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (telefono.isEmpty) return null;
    if (telefono.length != 10) return 'Ingresa un teléfono de 10 dígitos';
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final telefono = _telefonoController.text.replaceAll(RegExp(r'\D'), '');
    final exito = await auth.actualizarPerfil(
      nombre: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      telefono: telefono.isEmpty ? null : telefono,
      fotoUrl: _fotoUrl,
    );

    if (!mounted) return;

    if (exito) {
      Navigator.of(context).maybePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'No se pudo actualizar el perfil'),
        ),
      );
    }
  }

  Future<void> _elegirFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    XFile? archivo;
    try {
      archivo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1200,
        maxHeight: 1200,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir la cámara o la galería. Revisa los permisos de la aplicación.',
            ),
          ),
        );
      }
      return;
    }
    if (archivo == null || !mounted) return;
    setState(() => _subiendoFoto = true);
    try {
      final url = await _imagenService.subir(archivo, carpeta: 'perfil');
      if (mounted) setState(() => _fotoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

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
          'Editar Perfil',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    AppAvatar(radius: 64, url: _fotoUrl),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        onPressed: _subiendoFoto ? null : _elegirFoto,
                        tooltip: 'Cambiar foto',
                        icon: _subiendoFoto
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceContainerLow),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      LabeledTextField(
                        label: 'Nombre',
                        controller: _nombreController,
                        icon: Icons.person_outline_rounded,
                        hintText: 'Tu nombre completo',
                        validator: _validarNombre,
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Correo Electrónico',
                        controller: _correoController,
                        icon: Icons.mail_outline_rounded,
                        hintText: 'Tu correo electrónico',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validarCorreo,
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Teléfono',
                        controller: _telefonoController,
                        icon: Icons.call_outlined,
                        hintText: 'Tu número de teléfono',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 10,
                        validator: _validarTelefono,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Guardar Cambios',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
