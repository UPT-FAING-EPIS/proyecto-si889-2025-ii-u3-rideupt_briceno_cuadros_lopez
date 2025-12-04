// lib/screens/auth/auth_wrapper.dart (CORREGIDO)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/screens/auth/login_screen.dart';
import 'package:rideupt_app/screens/auth/admin_login_screen.dart';
import 'package:rideupt_app/screens/home/main_navigation_screen.dart';
import 'package:rideupt_app/screens/onboarding/onboarding_screen.dart';
import 'package:rideupt_app/screens/admin/admin_panel_screen.dart';
import 'package:rideupt_app/widgets/safe_area_wrapper.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Cachear el Future para evitar múltiples llamadas
  late final Future<bool> _onboardingCheck;

  @override
  void initState() {
    super.initState();
    _onboardingCheck = _checkOnboardingCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Debug: Verificar que estamos en web
    if (kIsWeb) {
      debugPrint('🌐 [AuthWrapper] Ejecutando en web');
    }
    
    // Si es web, mostrar solo panel administrativo
    if (kIsWeb) {
      return FutureBuilder<bool>(
        future: _onboardingCheck,
        builder: (context, snapshot) {
          // Mostrar loading mientras verifica
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                      colorScheme.surface,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }
          
          return Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              // Si está autenticado y es admin, mostrar panel
              if (authProvider.isAuthenticated && authProvider.user?.isAdmin == true) {
                return const AdminPanelScreen();
              }
              
              // Si está autenticado pero no es admin, mostrar mensaje
              if (authProvider.isAuthenticated && authProvider.user?.isAdmin != true) {
                return Scaffold(
                  body: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Acceso Restringido',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Esta aplicación web es solo para administradores. Por favor, usa la aplicación móvil para acceder como conductor o pasajero.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => authProvider.logout(),
                            child: const Text('Cerrar Sesión'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              // Si no está autenticado, mostrar login de admin (solo para web)
              return const AdminLoginScreen();
            },
          );
        },
      );
    }
    
    // Para móvil, seguir el flujo normal
    return FutureBuilder<bool>(
      future: _onboardingCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: SafeAreaWrapper(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.05),
                      colorScheme.surface,
                    ],
                    stops: const [0.0, 0.3],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          );
        }

        // Si el onboarding no se ha completado, mostrar pantalla de bienvenida
        if (!snapshot.data!) {
          return const OnboardingScreen();
        }

        // Si el onboarding está completo, proceder con la lógica de autenticación
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Si el usuario está autenticado, muestra la pantalla principal
            if (authProvider.isAuthenticated) {
              return const MainNavigationScreen();
            }

            // Si no está autenticado, mostrar directamente la pantalla de login
            return const LoginScreen();
          },
        );
      },
    );
  }

  Future<bool> _checkOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    debugPrint('📋 [AuthWrapper] Estado del onboarding: $completed');
    return completed;
  }
}