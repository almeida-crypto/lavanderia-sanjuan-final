import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_colors.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _authService = AuthService();

  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _verActual = false;
  bool _verNueva = false;
  bool _verConfirmar = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  bool get _nuevaEsSegura {
    final valor = _nuevaController.text;
    return valor.length >= 8 &&
        valor.contains(RegExp('[A-Z]')) &&
        valor.contains(RegExp(r'[0-9]'));
  }

  Future<void> _actualizarContrasena() async {
    setState(() => _error = null);

    if (_actualController.text.isEmpty ||
        _nuevaController.text.isEmpty ||
        _confirmarController.text.isEmpty) {
      setState(() => _error = 'Completa los tres campos.');
      return;
    }
    if (!_nuevaEsSegura) {
      setState(
        () => _error = 'La nueva contraseña debe tener al menos 8 caracteres, '
            'una mayúscula y un número.',
      );
      return;
    }
    if (_nuevaController.text != _confirmarController.text) {
      setState(() => _error = 'Las contraseñas nuevas no coinciden.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final correo = context.read<AuthProvider>().currentUser?.correo;
      if (correo == null || correo.isEmpty) {
        throw AuthException('No se pudo identificar el usuario actual');
      }

      await _authService.cambiarContrasena(
        correo: correo,
        passwordActual: _actualController.text,
        passwordNueva: _nuevaController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
      Navigator.of(context).maybePop();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          'Cambiar Contraseña',
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresa tu contraseña actual y la nueva para actualizar tu seguridad.',
                style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              _CampoContrasena(
                etiqueta: 'Contraseña Actual',
                icon: Icons.lock_outline_rounded,
                controller: _actualController,
                hint: 'Ingresa tu contraseña actual',
                obscureText: !_verActual,
                onToggleVisibilidad: () => setState(() => _verActual = !_verActual),
              ),
              const SizedBox(height: 16),
              _CampoContrasena(
                etiqueta: 'Nueva Contraseña',
                icon: Icons.vpn_key_outlined,
                controller: _nuevaController,
                hint: 'Crea una nueva contraseña',
                obscureText: !_verNueva,
                onToggleVisibilidad: () => setState(() => _verNueva = !_verNueva),
              ),
              const SizedBox(height: 16),
              _CampoContrasena(
                etiqueta: 'Confirmar Nueva Contraseña',
                icon: Icons.verified_user_outlined,
                controller: _confirmarController,
                hint: 'Repite la nueva contraseña',
                obscureText: !_verConfirmar,
                onToggleVisibilidad: () => setState(() => _verConfirmar = !_verConfirmar),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consejo de Seguridad',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usa al menos 8 caracteres, una mayúscula y un número.',
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.surface),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _actualizarContrasena,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Actualizar Contraseña',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoContrasena extends StatelessWidget {
  const _CampoContrasena({
    required this.etiqueta,
    required this.icon,
    required this.controller,
    required this.hint,
    required this.obscureText,
    required this.onToggleVisibilidad,
  });

  final String etiqueta;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final VoidCallback onToggleVisibilidad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.secondaryFixed,
            prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              onPressed: onToggleVisibilidad,
            ),
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 16, color: AppColors.secondary),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
