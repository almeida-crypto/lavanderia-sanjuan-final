import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/crear_cuenta_provider.dart';
import '../../../providers/direcciones_provider.dart';
import '../../../providers/metodos_pago_provider.dart';
import '../../../providers/preferencias_provider.dart';
import '../../../utils/app_colors.dart';
import '../../cliente/home_cliente/home_cliente_screen.dart';
import '../terminos_condiciones/terminos_condiciones_screen.dart';

class CrearCuentaScreen extends StatelessWidget {
  const CrearCuentaScreen({super.key});

  Future<void> _verTerminos(BuildContext context, CrearCuentaProvider form) async {
    final aceptados = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TerminosCondicionesScreen()),
    );
    if (aceptados == true) {
      form.toggleAceptaTerminos(true);
    }
  }

  Future<void> _registrarse(BuildContext context, CrearCuentaProvider form) async {
    if (!form.formKey.currentState!.validate()) return;

    if (!form.aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los Términos y Condiciones')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.registrar(
      nombre: form.nombreController.text.trim(),
      apellido: form.apellidoController.text.trim(),
      correo: form.correoController.text.trim(),
      telefono: form.telefonoController.text.trim(),
      password: form.passwordController.text,
    );

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'No se pudo crear la cuenta')),
      );
      return;
    }

    final usuarioId = auth.currentUser!.id;
    await Future.wait([
      context.read<PreferenciasProvider>().cargarParaUsuario(usuarioId),
      context.read<DireccionesProvider>().cargarParaUsuario(usuarioId),
      context.read<MetodosPagoProvider>().cargarParaUsuario(usuarioId),
    ]);
    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeClienteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CrearCuentaProvider(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurfaceVariant),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'FreshClean',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Consumer<CrearCuentaProvider>(
                  builder: (context, form, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear Cuenta',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ingresa tus datos para comenzar.',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: form.formKey,
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _RoundedTextField(
                                      controller: form.nombreController,
                                      hintText: 'Nombre',
                                      icon: Icons.person_outline_rounded,
                                      validator: (v) =>
                                          form.validateRequerido(v, mensaje: 'Ingresa tu nombre'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RoundedTextField(
                                      controller: form.apellidoController,
                                      hintText: 'Apellido',
                                      validator: (v) => form.validateRequerido(
                                        v,
                                        mensaje: 'Ingresa tu apellido',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _RoundedTextField(
                                controller: form.correoController,
                                hintText: 'Correo Electrónico',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: form.validateCorreo,
                              ),
                              const SizedBox(height: 12),
                              _RoundedTextField(
                                controller: form.telefonoController,
                                hintText: 'Teléfono (opcional)',
                                icon: Icons.call_outlined,
                                keyboardType: TextInputType.phone,
                                validator: form.validateTelefono,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _RoundedTextField(
                                controller: form.passwordController,
                                hintText: 'Contraseña',
                                icon: Icons.lock_outline_rounded,
                                obscureText: form.obscurePassword,
                                validator: form.validatePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    form.obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onPressed: form.toggleObscurePassword,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _RoundedTextField(
                                controller: form.confirmarPasswordController,
                                hintText: 'Confirmar Contraseña',
                                icon: Icons.lock_reset_rounded,
                                obscureText: form.obscureConfirmarPassword,
                                validator: form.validateConfirmarPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    form.obscureConfirmarPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onPressed: form.toggleObscureConfirmarPassword,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: form.aceptaTerminos,
                                      onChanged: form.toggleAceptaTerminos,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                          children: [
                                            const TextSpan(text: 'Acepto los '),
                                            TextSpan(
                                              text: 'Términos y Condiciones',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () => _verTerminos(context, form),
                                            ),
                                            const TextSpan(text: ' y la '),
                                            TextSpan(
                                              text: 'Política de Privacidad',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () => _verTerminos(context, form),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return ElevatedButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () => _registrarse(context, form),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Registrarse',
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded, size: 18),
                                            ],
                                          ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(text: '¿Ya tienes cuenta? '),
                                TextSpan(
                                  text: 'Inicia Sesión',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context).maybePop(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedTextField extends StatelessWidget {
  const _RoundedTextField({
    required this.controller,
    required this.hintText,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary, size: 20) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
