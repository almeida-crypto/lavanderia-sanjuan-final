import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/usuario.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_colors.dart';
import 'crear_empleado_screen.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminProvider>().cargarEmpleados();
  }

  void _mostrarError(BuildContext context, Object error, String fallback) {
    final mensaje = error.toString().contains('Exception: ') ? error.toString().split('Exception: ').last : fallback;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _cambiarRol(BuildContext context, Usuario empleado, UserRole nuevoRol, String actorId) async {
    try {
      await context.read<AdminProvider>().cambiarRolEmpleado(empleado.id, nuevoRol, actorId: actorId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${empleado.nombre} ahora es ${userRoleToString(nuevoRol)}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      _mostrarError(context, e, 'No se pudo actualizar el rol');
    }
  }

  Future<void> _cambiarEstado(BuildContext context, Usuario empleado, bool activa, String actorId) async {
    if (!activa) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Desactivar cuenta'),
          content: Text(
            '${empleado.nombre} no podrá iniciar sesión hasta que la reactives. '
            'No se borra ningún dato.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(dialogCtx).pop(true), child: const Text('Desactivar')),
          ],
        ),
      );
      if (confirmado != true) return;
    }

    if (!context.mounted) return;
    try {
      await context.read<AdminProvider>().cambiarEstadoEmpleado(empleado.id, activa, actorId: actorId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(activa ? '${empleado.nombre} fue reactivado' : '${empleado.nombre} fue desactivado')),
      );
    } catch (e) {
      if (!context.mounted) return;
      _mostrarError(context, e, 'No se pudo actualizar el estado de la cuenta');
    }
  }

  Future<void> _eliminar(BuildContext context, Usuario empleado, String actorId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          'Esto borra la cuenta de ${empleado.nombre} por completo y no se puede deshacer. '
          'Si solo quieres bloquearle el acceso, usa "Desactivar" en vez de esto.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    try {
      await context.read<AdminProvider>().eliminarEmpleado(empleado.id, actorId: actorId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cuenta de ${empleado.nombre} eliminada')),
      );
    } catch (e) {
      if (!context.mounted) return;
      _mostrarError(context, e, 'No se pudo eliminar la cuenta');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final empleados = provider.empleados;
    final miId = context.watch<AuthProvider>().currentUser?.id;

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
          'Empleados',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CrearEmpleadoScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: Text('Nueva', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: provider.isLoadingEmpleados && empleados.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : empleados.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aún no has creado cuentas de empleado.\nUsa "Nueva" para dar de alta a tu primer empleado.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<AdminProvider>().cargarEmpleados(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: empleados.length,
                      itemBuilder: (context, index) {
                        final empleado = empleados[index];
                        final esYoMismo = miId != null && miId == empleado.id;
                        return _EmpleadoCard(
                          empleado: empleado,
                          esYoMismo: esYoMismo,
                          onCambiarRol: (rol) => _cambiarRol(context, empleado, rol, miId ?? ''),
                          onCambiarEstado: (activa) => _cambiarEstado(context, empleado, activa, miId ?? ''),
                          onEliminar: () => _eliminar(context, empleado, miId ?? ''),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _EmpleadoCard extends StatelessWidget {
  const _EmpleadoCard({
    required this.empleado,
    required this.esYoMismo,
    required this.onCambiarRol,
    required this.onCambiarEstado,
    required this.onEliminar,
  });

  final Usuario empleado;
  final bool esYoMismo;
  final ValueChanged<UserRole> onCambiarRol;
  final ValueChanged<bool> onCambiarEstado;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final esAdmin = empleado.rol == UserRole.administrador;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: esAdmin ? AppColors.primary : AppColors.surfaceVariant),
      ),
      color: AppColors.surfaceContainerLowest,
      child: Opacity(
        opacity: empleado.activo ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryFixed,
                    child: Text(
                      empleado.nombre.isNotEmpty ? empleado.nombre.substring(0, 1).toUpperCase() : '?',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                empleado.nombre,
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (esYoMismo) ...[
                              const SizedBox(width: 6),
                              Text('(tú)', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                            ],
                            if (!empleado.activo) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Inactiva',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          empleado.correo,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.surfaceVariant),
              const SizedBox(height: 8),
              if (esYoMismo)
                Text(
                  'No puedes cambiar tu propio rol, estado ni eliminar tu cuenta.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                )
              else
                Row(
                  children: [
                    DropdownButton<UserRole>(
                      value: empleado.rol,
                      underline: const SizedBox(),
                      isDense: true,
                      items: [
                        DropdownMenuItem(
                          value: UserRole.empleado,
                          child: Text('Empleado', style: GoogleFonts.inter(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: UserRole.administrador,
                          child: Text('Administrador', style: GoogleFonts.inter(fontSize: 13)),
                        ),
                      ],
                      onChanged: (rol) {
                        if (rol != null && rol != empleado.rol) onCambiarRol(rol);
                      },
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: empleado.activo,
                      activeThumbColor: AppColors.primary,
                      onChanged: onCambiarEstado,
                    ),
                    IconButton(
                      onPressed: onEliminar,
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: 'Eliminar cuenta',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
