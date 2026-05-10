import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// ViewModels
import 'package:alimentaperu_app/viewmodels/login_viewmodel.dart';
import 'package:alimentaperu_app/viewmodels/menu_diario_viewmodel.dart';
import 'package:alimentaperu_app/viewmodels/estado_pagos_viewmodel.dart';
import 'package:alimentaperu_app/viewmodels/donacion_viewmodel.dart';

// Vistas
import 'package:alimentaperu_app/views/splash_screen.dart';
import 'package:alimentaperu_app/views/login_view.dart';
import 'package:alimentaperu_app/views/admin/admin_dashboard.dart';
import 'package:alimentaperu_app/views/admin/registro_menu/registro_menu_view.dart';
import 'package:alimentaperu_app/views/admin/reportes_view.dart';
import 'package:alimentaperu_app/views/admin/inventario/inventario_view.dart';
import 'package:alimentaperu_app/views/admin/inventario/registro_ingreso_view.dart';
import 'package:alimentaperu_app/views/admin/inventario/registro_salida.dart';
import 'package:alimentaperu_app/views/admin/inventario/reporte_stock_view.dart';
import 'package:alimentaperu_app/views/comensal/comensal_dashboard_view.dart';
import 'package:alimentaperu_app/views/comensal/menu_diario_view.dart';
import 'package:alimentaperu_app/views/comensal/estado_pagos_view.dart';
import 'package:alimentaperu_app/views/comensal/donacion_view.dart';
import 'package:alimentaperu_app/views/admin/Beneficiaria/beneficiarias_view.dart';
import 'package:alimentaperu_app/views/admin/Beneficiaria/padron_beneficiarios_view.dart';
import 'package:alimentaperu_app/views/admin/Beneficiaria/gestion_saldos_view.dart';
import 'package:alimentaperu_app/views/admin/Beneficiaria/gestion_donaciones_view.dart';
import 'package:alimentaperu_app/views/admin/Beneficiaria/registro_cocinera_view.dart';
import 'package:alimentaperu_app/views/registro_usuario_view.dart';
import 'package:alimentaperu_app/views/forgot_password_view.dart';

void main() async {
  // Asegura que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase antes de arrancar la app para que el resto sea instantáneo
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => MenuDiarioViewModel()),
        ChangeNotifierProvider(create: (_) => EstadoPagosViewModel()),
        ChangeNotifierProvider(create: (_) => DonacionViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Alimenta Perú',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1A4D2E),
          textTheme: GoogleFonts.urbanistTextTheme(),
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        // Al ya estar Firebase listo, entramos directo al Splash sin parpadeos
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginView(),
          '/registro': (context) => const RegistroUsuarioView(),
          '/forgot_password': (context) => const ForgotPasswordView(),

          // Rutas Administrativas
          '/dashboard': (context) => const AdminDashboard(),
          '/registro_menu': (context) => const RegistroMenuView(),
          '/beneficiarias': (context) => const GestionBeneficiariasView(),
          '/reportes': (context) => const ReportesView(),
          '/inventario': (context) => const InventarioView(),
          '/registro_ingreso': (context) => const RegistroIngresoView(),
          '/registro_salida': (context) => const RegistroSalidaView(),
          '/reporte_stock': (context) => const ReporteStockView(),

          // Módulo Comensal
          '/comensal_dashboard': (context) => const ComensalDashboardView(),
          '/donacion': (context) => const DonacionView(),
          '/menu_diario': (context) => const MenuDiarioView(),
          '/estado_pagos': (context) => const EstadoPagosView(),

          // Módulo Beneficiaria
          '/padron_lista': (context) => const PadronBeneficiariosView(),
          '/gestion_saldos': (context) => const GestionSaldosView(),
          '/registro_cocinera': (context) => const RegistroCocineraView(),
          '/gestion_donaciones': (context) => const GestionDonacionesView(),
        },
      ),
    );
  }
}
