import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/usuario.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/whatsapp_launcher.dart';

/// Pantalla de administración dedicada a la Configuración de Repartidores.
class RepartidoresConfigScreen extends StatefulWidget {
  const RepartidoresConfigScreen({super.key});

  @override
  State<RepartidoresConfigScreen> createState() => _RepartidoresConfigScreenState();
}

class _RepartidoresConfigScreenState extends State<RepartidoresConfigScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminProvider>().cargarEmpleados();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirDialogoCrearRepartidor(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nuevo Repartidor',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Crea una cuenta para el personal encargado de recolecciones y entregas.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Número telefónico',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v ?? '').replaceAll(RegExp(r'[^0-9]'), '').length < 10
                            ? 'Ingresa 10 dígitos' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (!v.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña Inicial',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (v) => (v == null || v.trim().length < 6) ? 'Mínimo 6 caracteres' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () => Navigator.pop(dialogContext),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
                ),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          setDialogState(() => guardando = true);
                          try {
                            await context.read<AdminProvider>().crearEmpleado(
                                  nombre: nameController.text.trim(),
                                  correo: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                  rol: UserRole.repartidor,
                                  telefono: phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                                );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Repartidor registrado con éxito'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => guardando = false);
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirDialogoCambiarPassword(BuildContext context, Usuario usuario) {
    final newPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Cambiar Contraseña', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nueva contraseña para ${usuario.nombre}:',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPassController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nueva Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => (v == null || v.trim().length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          setDialogState(() => guardando = true);
                          try {
                            final adminProv = context.read<AdminProvider>();
                            final currentAdmin = context.read<AuthProvider>().currentUser;
                            final adminEmail = currentAdmin?.correo ?? '';
                            
                            final passConfirmController = TextEditingController();
                            final confirmResult = await showDialog<String>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Confirmar Administrador'),
                                content: TextField(
                                  controller: passConfirmController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Tu contraseña de Administrador',
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, passConfirmController.text),
                                    child: const Text('Confirmar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmResult == null || confirmResult.isEmpty) {
                              setDialogState(() => guardando = false);
                              return;
                            }

                            await adminProv.cambiarPasswordEmpleado(
                                  usuario.id,
                                  nuevaPassword: newPassController.text.trim(),
                                  actorCorreo: adminEmail,
                                  actorPassword: confirmResult,
                                );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Contraseña actualizada con éxito')),
                            );
                          } catch (e) {
                            setDialogState(() => guardando = false);
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarEliminarRepartidor(BuildContext context, Usuario repartidor) {
    final currentAdmin = context.read<AuthProvider>().currentUser;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Repartidor'),
        content: Text('¿Deseas eliminar permanentemente la cuenta de "${repartidor.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await context.read<AdminProvider>().eliminarEmpleado(
                      repartidor.id,
                      actorId: currentAdmin?.id ?? '',
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Repartidor eliminado')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarTelefono(BuildContext context, Usuario repartidor) async {
    final controller = TextEditingController(text: repartidor.telefono);
    final telefono = await showDialog<String>(context: context, builder: (c) => AlertDialog(
      title: const Text('Teléfono del repartidor'),
      content: TextField(controller: controller, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Número telefónico')),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: const Text('Guardar'))],
    ));
    controller.dispose();
    if (telefono == null || !context.mounted) return;
    if (telefono.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un número de 10 dígitos')));
      return;
    }
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    try { await context.read<AdminProvider>().cambiarTelefonoEmpleado(repartidor.id, telefonoLimpio); }
    catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final currentAdmin = context.watch<AuthProvider>().currentUser;
    final puedeAdministrar = currentAdmin?.rol == UserRole.administrador;
    final query = _searchController.text.trim().toLowerCase();

    final todosEmpleados = adminProvider.empleados;
    final repartidores = todosEmpleados.where((e) => e.rol == UserRole.repartidor).toList();

    final repartidoresFiltrados = repartidores.where((r) {
      if (query.isEmpty) return true;
      return r.nombre.toLowerCase().contains(query) || r.correo.toLowerCase().contains(query);
    }).toList();

    final repartidoresActivos = repartidores.where((r) => r.activo).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Configuración de Repartidores',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
      floatingActionButton: puedeAdministrar
          ? FloatingActionButton.extended(
              onPressed: () => _abrirDialogoCrearRepartidor(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.two_wheeler_rounded),
              label: Text('Nuevo Repartidor', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => adminProvider.cargarEmpleados(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal de Reparto',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$repartidoresActivos activos de ${repartidores.length} registrados',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Search Box
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar repartidor por nombre o correo...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.surfaceVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.surfaceVariant),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (adminProvider.isLoadingEmpleados && repartidores.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (repartidoresFiltrados.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.two_wheeler_outlined, size: 56, color: AppColors.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        repartidores.isEmpty
                            ? 'No hay repartidores registrados'
                            : 'No se encontraron resultados',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        repartidores.isEmpty
                            ? 'Haz clic en el botón "Nuevo Repartidor" para registrar el personal de entregas.'
                            : 'Intenta con otro término de búsqueda.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: repartidoresFiltrados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final rep = repartidoresFiltrados[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: rep.activo ? AppColors.surfaceVariant : AppColors.errorContainer,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: rep.activo ? AppColors.primaryFixed : AppColors.surfaceContainerHigh,
                          child: Icon(
                            Icons.directions_bike_rounded,
                            color: rep.activo ? AppColors.primary : AppColors.onSurfaceVariant,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                rep.nombre,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: rep.activo ? AppColors.onSurface : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: rep.activo ? AppColors.secondaryContainer : AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                rep.activo ? 'Activo' : 'Inactivo',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: rep.activo ? AppColors.onSecondaryContainer : AppColors.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              rep.correo,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                            ),
                            if (rep.telefono?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => abrirWhatsApp(rep.telefono),
                                child: Row(
                                  children: [
                                    const Icon(Icons.chat_outlined, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(rep.telefono!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.badge_outlined, size: 14, color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  'Rol: Repartidor',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (value) async {
                            if (value == 'estado') {
                              try {
                                await adminProvider.cambiarEstadoEmpleado(
                                  rep.id,
                                  !rep.activo,
                                  actorId: currentAdmin?.id ?? '',
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      rep.activo
                                          ? 'Repartidor desactivado'
                                          : 'Repartidor activado',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            } else if (value == 'password') {
                              _abrirDialogoCambiarPassword(context, rep);
                            } else if (value == 'telefono') {
                              _editarTelefono(context, rep);
                            } else if (value == 'eliminar') {
                              _confirmarEliminarRepartidor(context, rep);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'telefono',
                              child: Row(children: [Icon(Icons.phone_outlined, size: 18, color: AppColors.primary), SizedBox(width: 8), Text('Editar Teléfono')]),
                            ),
                            PopupMenuItem(
                              value: 'estado',
                              child: Row(
                                children: [
                                  Icon(
                                    rep.activo ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                    size: 18,
                                    color: rep.activo ? AppColors.error : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(rep.activo ? 'Desactivar Cuenta' : 'Activar Cuenta'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'password',
                              child: Row(
                                children: [
                                  Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Cambiar Contraseña'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Eliminar Repartidor'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
