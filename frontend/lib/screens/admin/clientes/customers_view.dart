import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/usuario.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_colors.dart';

class Customer {
  Customer({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.orderCount,
    required this.initials,
    this.avatarUrl,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final int orderCount;
  final String initials;
  final String? avatarUrl;
}

class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0; // 0: Clientes, 1: Empleados

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().cargarEmpleados();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          customer.initials,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            customer.email,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.surfaceVariant),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.phone_outlined, 'Teléfono', customer.phone),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.location_on_outlined, 'Dirección', customer.address),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.receipt_long_outlined,
                  'Pedidos Realizados',
                  '${customer.orderCount} pedidos en total',
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddEmpleadoDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole rolSeleccionado = UserRole.empleado;
    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Agregar Nueva Cuenta',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un correo' : null,
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: rolSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: UserRole.empleado, child: Text('Empleado')),
                        DropdownMenuItem(value: UserRole.administrador, child: Text('Administrador')),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => rolSeleccionado = value);
                      },
                    ),
                  ],
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
                                  rol: rolSeleccionado,
                                );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cuenta registrada con éxito')),
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
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Agregar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditEmpleadoDialog(BuildContext context, Usuario empleado, String actorId) {
    final adminCorreo = context.read<AuthProvider>().currentUser?.correo ?? '';
    UserRole rolSeleccionado = empleado.rol == UserRole.cliente ? UserRole.empleado : empleado.rol;
    final nuevaPasswordController = TextEditingController();
    final confirmarPasswordController = TextEditingController();
    final adminPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool mostrarPasswords = false;
    bool guardando = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Editar Cuenta', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(empleado.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(empleado.correo, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        initialValue: rolSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: UserRole.empleado, child: Text('Empleado')),
                          DropdownMenuItem(value: UserRole.administrador, child: Text('Administrador')),
                        ],
                        onChanged: (value) {
                          if (value != null) setDialogState(() => rolSeleccionado = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.surfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'Restablecer contraseña',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Por seguridad, las contraseñas no pueden mostrarse ni recuperarse. Solo puedes definir una nueva y deberás confirmar tu propia contraseña de administrador. Deja estos campos vacíos si no quieres cambiarla.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nuevaPasswordController,
                        obscureText: !mostrarPasswords,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(mostrarPasswords ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setDialogState(() => mostrarPasswords = !mostrarPasswords),
                          ),
                        ),
                        validator: (v) {
                          if ((v == null || v.isEmpty) && confirmarPasswordController.text.isEmpty) return null;
                          if (v == null || v.trim().length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmarPasswordController,
                        obscureText: !mostrarPasswords,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar nueva contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if (nuevaPasswordController.text.isEmpty) return null;
                          if (v != nuevaPasswordController.text) return 'No coincide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: adminPasswordController,
                        obscureText: !mostrarPasswords,
                        decoration: const InputDecoration(
                          labelText: 'Tu contraseña de administrador',
                          prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                        ),
                        validator: (v) {
                          if (nuevaPasswordController.text.isEmpty) return null;
                          if (v == null || v.isEmpty) return 'Requerida para confirmar el cambio';
                          return null;
                        },
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
                          final adminProvider = context.read<AdminProvider>();
                          try {
                            if (rolSeleccionado != empleado.rol) {
                              await adminProvider.cambiarRolEmpleado(empleado.id, rolSeleccionado, actorId: actorId);
                            }
                            if (nuevaPasswordController.text.isNotEmpty) {
                              await adminProvider.cambiarPasswordEmpleado(
                                empleado.id,
                                nuevaPassword: nuevaPasswordController.text.trim(),
                                actorCorreo: adminCorreo,
                                actorPassword: adminPasswordController.text,
                              );
                            }
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cambios guardados')),
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
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarCambioEstado(BuildContext context, Usuario empleado, String actorId) async {
    final activar = !empleado.activo;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          activar ? 'Activar Cuenta' : 'Desactivar Cuenta',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          activar
              ? '¿Reactivar el acceso de "${empleado.nombre}" (${empleado.correo})? Podrá iniciar sesión de nuevo.'
              : '¿Desactivar temporalmente a "${empleado.nombre}" (${empleado.correo})? No podrá iniciar sesión hasta que la reactives. Sus datos se conservan.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: activar ? AppColors.primary : AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(activar ? 'Activar' : 'Desactivar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    try {
      await context.read<AdminProvider>().cambiarEstadoEmpleado(empleado.id, activar, actorId: actorId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(activar ? 'Cuenta activada' : 'Cuenta desactivada')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showDeleteEmpleadoDialog(BuildContext context, Usuario empleado, String actorId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Eliminar Cuenta',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.error),
          ),
          content: Text(
            '¿Eliminar permanentemente la cuenta de "${empleado.nombre}" (${empleado.correo})?\nEsta acción no se puede deshacer. Si solo quieres quitarle el acceso temporalmente, usa "Desactivar" en su lugar.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await context.read<AdminProvider>().eliminarEmpleado(empleado.id, actorId: actorId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cuenta eliminada')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Eliminar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    const etiquetas = ['Clientes', 'Empleados'];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < etiquetas.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == i ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    etiquetas[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedTabIndex == i ? Colors.white : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final actorId = context.watch<AuthProvider>().currentUser?.id ?? '';
    final pedidos = adminProvider.pedidos;
    final empleados = adminProvider.empleados;

    final porCorreo = <String, Customer>{};
    for (final pedido in pedidos) {
      final key = pedido.clienteEmail.toLowerCase();
      final anterior = porCorreo[key];
      final partes = pedido.clienteNombre.trim().split(RegExp(r'\s+'));
      final iniciales = partes.where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
      porCorreo[key] = Customer(
        name: pedido.clienteNombre,
        email: pedido.clienteEmail,
        phone: pedido.clienteTelefono,
        address: pedido.clienteDireccion,
        orderCount: (anterior?.orderCount ?? 0) + 1,
        initials: iniciales.isEmpty ? 'CL' : iniciales,
      );
    }
    final customers = porCorreo.values.toList();
    final query = _searchController.text.toLowerCase().trim();

    final filteredCustomers = customers.where((customer) {
      return query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query);
    }).toList();

    final filteredEmpleados = empleados.where((emp) {
      return query.isEmpty ||
          emp.nombre.toLowerCase().contains(query) ||
          emp.correo.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Title and Selector Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedTabIndex == 0 ? 'Directorio de Clientes' : 'Gestión de Empleados',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: AppColors.onSurface,
                ),
              ),
              if (_selectedTabIndex == 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddEmpleadoDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text('Agregar Cuenta', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _selectedTabIndex == 0
                    ? 'Gestiona y visualiza la información de tus clientes.'
                    : 'Administra las cuentas que tienen acceso al panel de empleado.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildTabSelector(),
              const SizedBox(height: 16),

              // Metrics & Search Bento Grid Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  final totalCard = _selectedTabIndex == 0
                      ? _buildTotalCustomersCard(customers.length)
                      : _buildTotalEmpleadosCard(empleados.length);
                  return isWide
                      ? Row(
                          children: [
                            totalCard,
                            const SizedBox(width: 16),
                            Expanded(child: _buildSearchBar()),
                          ],
                        )
                      : Column(
                          children: [
                            totalCard,
                            const SizedBox(height: 12),
                            _buildSearchBar(),
                          ],
                        );
                },
              ),
            ],
          ),
        ),

        // List Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTabIndex == 0 ? 'Lista de Clientes' : 'Lista de Empleados',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                '${_selectedTabIndex == 0 ? filteredCustomers.length : filteredEmpleados.length} mostrados',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Body List (Clientes vs Empleados)
        Expanded(
          child: _selectedTabIndex == 0
              ? (filteredCustomers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.outline),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron clientes',
                            style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        return _buildCustomerItem(context, customer);
                      },
                    ))
              : (adminProvider.isLoadingEmpleados
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filteredEmpleados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.badge_outlined, size: 48, color: AppColors.outline),
                              const SizedBox(height: 12),
                              Text(
                                'No hay empleados registrados',
                                style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredEmpleados.length,
                          itemBuilder: (context, index) {
                            final empleado = filteredEmpleados[index];
                            return _buildEmpleadoItem(context, empleado, actorId);
                          },
                        )),
        ),
      ],
    );
  }

  Widget _buildTotalCustomersCard(int total, {bool fullWidth = false}) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clientes Totales',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$total',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: card) : card;
  }

  Widget _buildTotalEmpleadosCard(int total, {String etiqueta = 'Empleados Activos', bool fullWidth = false}) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$total',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: card) : card;
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() {}),
      decoration: InputDecoration(
        hintText: _selectedTabIndex == 0 ? 'Buscar clientes...' : 'Buscar empleados...',
        hintStyle: GoogleFonts.inter(color: AppColors.outline),
        prefixIcon: const Icon(Icons.search, color: AppColors.outline),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.outline),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildCustomerItem(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      color: AppColors.surfaceContainerLowest,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCustomerDetails(context, customer),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    customer.initials,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Actividad',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${customer.orderCount} Pedidos',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpleadoItem(BuildContext context, Usuario empleado, String actorId) {
    final partes = empleado.nombre.trim().split(RegExp(r'\s+'));
    final iniciales = partes.where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    final esUnoMismo = empleado.id == actorId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: empleado.activo ? AppColors.secondaryContainer : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      iniciales.isEmpty ? 'EMP' : iniciales,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: empleado.activo ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                    ),
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
                              empleado.nombre.isEmpty ? empleado.correo : empleado.nombre,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (esUnoMismo)
                            Text('(tú)', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        empleado.correo,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: !empleado.activo
                        ? AppColors.errorContainer
                        : empleado.rol == UserRole.administrador
                            ? AppColors.secondaryContainer
                            : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    !empleado.activo
                        ? 'INACTIVA'
                        : empleado.rol == UserRole.administrador
                            ? 'ADMINISTRADOR'
                            : 'EMPLEADO',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                if (!esUnoMismo) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    onPressed: () => _showEditEmpleadoDialog(context, empleado, actorId),
                    tooltip: 'Editar (rol y contraseña)',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      empleado.activo ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: empleado.activo ? AppColors.error : AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => _confirmarCambioEstado(context, empleado, actorId),
                    tooltip: empleado.activo ? 'Desactivar' : 'Activar',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () => _showDeleteEmpleadoDialog(context, empleado, actorId),
                    tooltip: 'Eliminar cuenta',
                  ),
                ] else
                  Text(
                    'No puedes modificar tu propia cuenta desde aquí',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
