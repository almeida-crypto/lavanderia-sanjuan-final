import 'package:flutter/material.dart';

class CrearCuentaProvider extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final correoController = TextEditingController();
  final telefonoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmarPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _obscureConfirmarPassword = true;
  bool get obscureConfirmarPassword => _obscureConfirmarPassword;

  bool _aceptaTerminos = false;
  bool get aceptaTerminos => _aceptaTerminos;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirmarPassword() {
    _obscureConfirmarPassword = !_obscureConfirmarPassword;
    notifyListeners();
  }

  void toggleAceptaTerminos(bool? value) {
    _aceptaTerminos = value ?? false;
    notifyListeners();
  }

  String? validateRequerido(String? value, {required String mensaje}) {
    if (value == null || value.trim().isEmpty) return mensaje;
    return null;
  }

  String? validateCorreo(String? value) {
    final correo = value?.trim() ?? '';
    if (correo.isEmpty) return 'Ingresa tu correo';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(correo)) return 'Correo inválido';
    return null;
  }

  String? validateTelefono(String? value) {
    final telefono = value?.trim() ?? '';
    if (telefono.isEmpty) return null;
    if (telefono.length < 10) return 'Teléfono inválido';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? validateConfirmarPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != passwordController.text) return 'Las contraseñas no coinciden';
    return null;
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    correoController.dispose();
    telefonoController.dispose();
    passwordController.dispose();
    confirmarPasswordController.dispose();
    super.dispose();
  }
}
