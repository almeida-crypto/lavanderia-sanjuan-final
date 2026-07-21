import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/pedido_admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notificaciones_store.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/doble_back_para_salir.dart';
import '../../admin/home_administrador/dashboard_view.dart';
import '../../admin/home_administrador/perfil_administrador_screen.dart';
import '../../admin/pedidos/orders_view.dart';
import '../notificaciones/notificaciones_empleado_screen.dart';

class HomeEmpleadoScreen extends StatefulWidget {
  const HomeEmpleadoScreen({super.key});

  @override
  State<HomeEmpleadoScreen> createState() => _HomeEmpleadoScreenState();
}

class _HomeEmpleadoScreenState extends State<HomeEmpleadoScreen> {
  int _selectedIndex = 0;
  int _notificacionesNoLeidas = 0;

  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      DashboardView(onViewOrdersTap: () => _onItemTapped(1)),
      const OrdersView(),
    ];
    context.read<AdminProvider>().cargarPedidos().whenComplete(_actualizarNotificaciones);
  }

  String _claveDe(PedidoAdmin pedido) => 'pedido_${pedido.id}_${pedido.estado.name}';

  Future<void> _actualizarNotificaciones() async {
    final usuarioId = context.read<AuthProvider>().currentUser?.id;
    final store = NotificacionesStore(namespace: 'empleado', usuarioId: usuarioId);
    await store.cargar();
    final pedidos = context.read<AdminProvider>().pedidos.where(
          (p) => p.estado == PedidoEstado.recibido || p.estado == PedidoEstado.atencion,
        );
    final cantidad = pedidos.where((pedido) {
      final clave = _claveDe(pedido);
      return !store.leidas.contains(clave) &&
          !store.archivadas.contains(clave) &&
          !store.eliminadas.contains(clave);
    }).length;
    if (mounted) setState(() => _notificacionesNoLeidas = cantidad);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Mismo motivo que en el panel de admin: las pestañas viven en un
    // IndexedStack y solo cargaban datos una vez al iniciar sesión.
    context.read<AdminProvider>().cargarPedidos().whenComplete(_actualizarNotificaciones);
  }

  @override
  Widget build(BuildContext context) {
    return DobleBackParaSalir(
      antesDeSalir: () {
        if (_selectedIndex != 0) {
          _onItemTapped(0);
          return true;
        }
        return false;
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_laundry_service_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'FreshClean',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AdminProvider>(
            builder: (context, _, __) {
              final pendientes = _notificacionesNoLeidas;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notificaciones',
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificacionesEmpleadoScreen(),
                        ),
                      );
                      await _actualizarNotificaciones();
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  if (pendientes > 0)
                    Positioned(
                      right: 5,
                      top: 4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 17),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          pendientes > 9 ? '9+' : '$pendientes',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PerfilAdministradorScreen()),
            ),
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceContainerHigh,
              child: Icon(Icons.person_outline, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _views,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurfaceVariant,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Panel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Pedidos',
            ),
          ],
        ),
      ),
      ),
    );
  }
}
