import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/usuario.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/direcciones_provider.dart';
import '../../../providers/login_provider.dart';
import '../../../providers/metodos_pago_provider.dart';
import '../../../providers/preferencias_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/labeled_text_field.dart';
import '../../admin/home_administrador/home_administrador_screen.dart';
import '../../cliente/home_cliente/home_cliente_screen.dart';
import '../../empleado/home_empleado/home_empleado_screen.dart';
import '../../repartidor/home_repartidor/home_repartidor_screen.dart';
import '../recuperar_contrasena/recuperar_contrasena_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Widget _pantallaInicial(BuildContext context, Usuario usuario) {
    final esEmpleado = usuario.rol == UserRole.empleado ||
        context.read<AdminProvider>().esEmpleadoEmail(usuario.correo);

    if (usuario.rol == UserRole.administrador) {
      return const HomeAdministradorScreen();
    }
    if (usuario.rol == UserRole.repartidor) {
      return const HomeRepartidorScreen();
    }
    if (esEmpleado) {
      return const HomeEmpleadoScreen();
    }
    return const HomeClienteScreen();
  }

  Future<void> _submit(BuildContext context, LoginProvider login) async {
    if (!login.formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      correo: login.emailController.text,
      password: login.passwordController.text,
    );

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'No se pudo iniciar sesión')),
      );
      return;
    }

    final usuario = auth.currentUser;
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo recuperar la sesión')),
      );
      return;
    }

    // Estos datos complementan la pantalla de inicio. Una falla temporal al
    // cargarlos no debe devolver al usuario al formulario si la sesión ya se
    // inició correctamente.
    try {
      await Future.wait([
        context.read<PreferenciasProvider>().cargarParaUsuario(usuario.id),
        context.read<DireccionesProvider>().cargarParaUsuario(usuario.id),
        context.read<MetodosPagoProvider>().cargarParaUsuario(usuario.id),
      ]);
    } catch (_) {
      // Las pantallas vuelven a solicitar sus datos al abrirse.
    }
    if (!context.mounted || auth.currentUser == null) return;

    final destino = _pantallaInicial(context, usuario);
    login.emailController.clear();
    login.passwordController.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destino),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Iniciar Sesión',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Consumer2<LoginProvider, AuthProvider>(
                builder: (context, login, auth, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Form(
                        key: login.formKey,
                        child: Column(
                          children: [
                            LabeledTextField(
                              label: 'Correo Electrónico',
                              controller: login.emailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: 'tu@correo.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: login.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            LabeledTextField(
                              label: 'Contraseña',
                              controller: login.passwordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: '••••••••',
                              obscureText: login.obscurePassword,
                              validator: login.validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  login.obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                onPressed: login.toggleObscurePassword,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RecuperarContrasenaScreen(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => _submit(context, login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
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
                            : Text(
                                'Iniciar Sesión',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
    );
  }
}
