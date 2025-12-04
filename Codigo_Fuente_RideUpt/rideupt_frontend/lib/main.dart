import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:rideupt_app/firebase_options.dart';
import 'package:rideupt_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/screens/splash/splash_screen.dart';
import 'package:rideupt_app/screens/auth/auth_wrapper.dart';
import 'package:rideupt_app/screens/onboarding/terms_conditions_screen.dart';
import 'package:rideupt_app/screens/onboarding/privacy_policy_screen.dart';
import 'package:rideupt_app/screens/driver/become_driver_screen.dart';
import 'package:rideupt_app/screens/profile/driver_profile_screen.dart';
import 'package:rideupt_app/screens/admin/admin_panel_screen.dart';
import 'package:rideupt_app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar sistema de modo edge-to-edge solo para móvil (no disponible en web)
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    
    // Configurar colores de la barra de estado y navegación
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  
  // Inicializar Firebase (necesario para Google Sign-In en web también)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('✅ Firebase inicializado correctamente');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Error al inicializar Firebase: $e');
    debugPrint('Stack: $stackTrace');
    // Continuar de todas formas, algunos servicios pueden funcionar sin Firebase
  }
  
  // Inicializar notificaciones solo en móvil (web no necesita notificaciones push)
  if (!kIsWeb) {
    try {
      await NotificationService().initWithoutPermissions();
    } catch (e) {
      debugPrint('⚠️ Error al inicializar notificaciones: $e');
    }
  }
  
  // Configurar manejo de errores global
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      debugPrint('❌ Error en widget: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar la aplicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  details.exception.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos MultiProvider para gestionar ambos providers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // TripProvider depende de AuthProvider para obtener el token
        ChangeNotifierProxyProvider<AuthProvider, TripProvider>(
          create: (_) => TripProvider(null),
          update: (_, auth, previous) => TripProvider(auth),
        ),
      ],
      child: MaterialApp(
        title: 'RideUPT',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // Manejar errores de construcción
        builder: (context, child) {
          // Actualizar colores de la barra de estado según el tema (solo en móvil)
          if (!kIsWeb) {
            final brightness = Theme.of(context).brightness;
            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
              ),
            );
          }
          
          return MediaQuery(
            // Asegurar que el texto no se escale demasiado pequeño
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler.clamp(
                minScaleFactor: 0.8,
                maxScaleFactor: 1.2,
              ),
            ),
            child: child!,
          );
        },
        home: const SplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/auth': (context) => const AuthWrapper(),
          '/terms': (context) => const TermsConditionsScreen(),
          '/privacy': (context) => const PrivacyPolicyScreen(),
          '/become-driver': (context) => const BecomeDriverScreen(),
          '/driver-profile': (context) => const DriverProfileScreen(),
          '/admin-panel': (context) => const AdminPanelScreen(),
        },
      ),
    );
  }
}