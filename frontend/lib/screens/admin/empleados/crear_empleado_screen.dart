import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/usuario.dart';
import '../../../providers/admin_provider.dart';
import '../../../utils/app_colors.dart';

class CrearEmpleadoScreen extends StatefulWidget {
  const CrearEmpleadoScreen({super.key});

  @override
  State<CrearEmpleadoScreen> createState() => _CrearEmpleadoScreenState();
}

class _CrearEmpleadoScreenState extends State<CrearEmpleadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _rol = UserRole.empleado;
  bool _isSaving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await context.read<AdminProvider>().crearEmpleado(
            nombre: _nombreController.text.trim(),
            correo: _correoController.text.trim(),
            password: _passwordController.text,
            rol: _rol,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada con éxito')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final mensaje = e.toString().contains('Exception: ') ? e.toString().split('Exception: ').last : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje ?? 'No se pudo crear la cuenta')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  @override
  Widget build(BuildContext context) {
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
          'Nueva Cuenta',
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
                Text(
                  'La cuenta queda activa de inmediato con esta contraseña; el empleado puede cambiarla después desde su perfil.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                  decoration: _decoration('Nombre completo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                  decoration: _decoration('Correo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  decoration: _decoration('Contraseña temporal'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  initialValue: _rol,
                  decoration: _decoration('Rol'),
                  items: const [
                    DropdownMenuItem(value: UserRole.empleado, child: Text('Empleado')),
                    DropdownMenuItem(value: UserRole.administrador, child: Text('Administrador')),
                  ],
                  onChanged: (rol) {
                    if (rol != null) setState(() => _rol = rol);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _rol == UserRole.empleado
                      ? 'Un empleado puede usar Panel, Pedidos y Clientes, pero no puede modificar Servicios, precios ni promociones.'
                      : 'Un administrador tiene acceso completo, incluida la gestión de Servicios y de otras cuentas.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _crear,
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
                          'Crear Cuenta',
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
