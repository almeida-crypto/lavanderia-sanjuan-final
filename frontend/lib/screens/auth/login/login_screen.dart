import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/usuario.dart';
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
import '../crear_cuenta/crear_cuenta_screen.dart';
import '../recuperar_contrasena/recuperar_contrasena_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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

    final usuarioId = auth.currentUser!.id;
    await Future.wait([
      context.read<PreferenciasProvider>().cargarParaUsuario(usuarioId),
      context.read<DireccionesProvider>().cargarParaUsuario(usuarioId),
      context.read<MetodosPagoProvider>().cargarParaUsuario(usuarioId),
    ]);
    if (!context.mounted) return;

    final esEmpleado = auth.currentUser!.rol == UserRole.empleado ||
        context.read<AdminProvider>().esEmpleadoEmail(auth.currentUser!.correo);

    final Widget destino;
    if (auth.currentUser!.rol == UserRole.administrador) {
      destino = const HomeAdministradorScreen();
    } else if (auth.currentUser!.rol == UserRole.repartidor) {
      destino = const HomeRepartidorScreen();
    } else if (esEmpleado) {
      destino = const HomeEmpleadoScreen();
    } else {
      destino = const HomeClienteScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destino),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
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
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.local_laundry_service_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'FreshClean',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Ropa fresca, vida simple.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
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
                      const SizedBox(height: 32),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.secondary,
                            ),
                            children: [
                              const TextSpan(text: '¿No tienes cuenta? '),
                              TextSpan(
                                text: 'Crea una',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CrearCuentaScreen(),
                                    ),
                                  ),
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
    );
  }
}
