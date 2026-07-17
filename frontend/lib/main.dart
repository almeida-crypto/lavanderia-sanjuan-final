import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/direcciones_provider.dart';
import 'providers/login_provider.dart';
import 'providers/metodos_pago_provider.dart';
import 'providers/preferencias_provider.dart';
import 'screens/auth/login/login_screen.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => DireccionesProvider()),
        ChangeNotifierProvider(create: (_) => MetodosPagoProvider()),
        ChangeNotifierProvider(create: (_) => PreferenciasProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'Lavanderia San Juan',
        scrollBehavior: const AppScrollBehavior(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.surface,
          textTheme: GoogleFonts.interTextTheme(),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
