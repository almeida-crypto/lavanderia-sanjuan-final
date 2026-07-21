import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/usuario.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/direcciones_provider.dart';
import 'providers/login_provider.dart';
import 'providers/metodos_pago_provider.dart';
import 'providers/opciones_catalogo_provider.dart';
import 'providers/preferencias_provider.dart';
import 'providers/servicios_provider.dart';
import 'screens/admin/home_administrador/home_administrador_screen.dart';
import 'screens/auth/login/bienvenida_screen.dart';
import 'screens/cliente/home_cliente/home_cliente_screen.dart';
import 'screens/empleado/home_empleado/home_empleado_screen.dart';
import 'screens/repartidor/home_repartidor/home_repartidor_screen.dart';
import 'utils/app_colors.dart';
import 'utils/app_scroll_behavior.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..cargarUsuarioGuardado()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => DireccionesProvider()),
        ChangeNotifierProvider(create: (_) => MetodosPagoProvider()),
        ChangeNotifierProvider(create: (_) => PreferenciasProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ServiciosProvider()..cargar()),
        ChangeNotifierProvider(create: (_) => OpcionesCatalogoProvider()..cargar()),
      ],
      child: MaterialApp(
        title: 'Lavanderia San Juan',
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX'), Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        scrollBehavior: const AppScrollBehavior(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.surface,
          textTheme: GoogleFonts.interTextTheme(),
        ),
        // La app está diseñada con tamaños de texto fijos (no usa unidades
        // relativas). Si el teléfono tiene configurado un tamaño de fuente u
        // "pantalla" del sistema distinto al que se usó para diseñar (muy
        // común entre celulares distintos), Android escala el texto y eso
        // desborda las tarjetas/columnas de ancho fijo, viéndose amontonado.
        // Limitar el rango evita que un ajuste de accesibilidad del sistema
        // rompa el diseño, sin bloquear la accesibilidad por completo.
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final textScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: textScaler),
            child: child!,
          );
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.inicializando) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (auth.currentUser == null) {
      return const BienvenidaScreen();
    }

    final usuario = auth.currentUser!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreferenciasProvider>().cargarParaUsuario(usuario.id);
      context.read<DireccionesProvider>().cargarParaUsuario(usuario.id);
      context.read<MetodosPagoProvider>().cargarParaUsuario(usuario.id);
    });

    final esEmpleado = usuario.rol == UserRole.empleado ||
        context.read<AdminProvider>().esEmpleadoEmail(usuario.correo);

    if (usuario.rol == UserRole.administrador) {
      return const HomeAdministradorScreen();
    } else if (usuario.rol == UserRole.repartidor) {
      return const HomeRepartidorScreen();
    } else if (esEmpleado) {
      return const HomeEmpleadoScreen();
    } else {
      return const HomeClienteScreen();
    }
  }
}
