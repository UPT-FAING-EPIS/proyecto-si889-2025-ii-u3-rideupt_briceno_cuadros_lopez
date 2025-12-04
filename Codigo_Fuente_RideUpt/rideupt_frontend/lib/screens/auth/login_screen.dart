// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/home/main_navigation_screen.dart';
import '../../widgets/google_signin_button.dart';
import '../../widgets/lottie_loading.dart';
import '../../widgets/safe_area_wrapper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Intentar auto-login sin modificar el estado del provider
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.tryAutoLogin();
    } catch (e) {
      debugPrint('Auto-login falló: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // Mostrar indicador de carga mientras se inicializa
    if (_isInitializing) {
      return Scaffold(
        body: Container(
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
          child: LottieLoading(
            message: 'Cargando...',
            messageColor: colorScheme.onSurface,
          ),
        ),
      );
    }

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
        child: SafeAreaWrapper(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: ResponsivePadding(
                mobile: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                tablet: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                desktop: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                child: ResponsiveContainer(
                  maxWidth: 500,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isTablet ? 40 : MediaQuery.of(context).size.height * 0.05),
                    
                    // Lottie Animation
                    Container(
                      width: isTablet ? 200 : 150,
                      height: isTablet ? 200 : 150,
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Lottie.asset(
                        'assets/lottie/Loading.json',
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 32 : 24),
                    
                    // Título con diseño consistente
                    Text(
                      'RideUpt',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colorScheme.onPrimary,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Comparte viajes con tu comunidad UPT',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.9),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: isTablet ? 48 : 40),
                    
                    // Card de login con diseño consistente
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 32 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Inicia sesión',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Mensaje especial para web
                            if (kIsWeb) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings, color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Acceso solo para administradores',
                                        style: TextStyle(
                                          color: Colors.orange[900],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            Text(
                              kIsWeb 
                                ? 'Usa tu correo institucional de administrador @virtual.upt.pe'
                                : 'Usa tu correo institucional @virtual.upt.pe',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Botón de Google Sign-In
                            GoogleSignInButton(
                              onSuccess: (userData) async {
                                debugPrint('✅ Google Sign-In exitoso: ${userData['email']}');
                                
                                // Guardar contexto ANTES de cualquier await
                                if (!mounted) return;
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final colorScheme = Theme.of(context).colorScheme;
                                
                                try {
                                  debugPrint('🔐 [LoginScreen] Guardando datos de autenticación...');
                                  
                                  // Guardar datos
                                  const storage = FlutterSecureStorage();
                                  await storage.write(key: 'token', value: userData['token']);
                                  await storage.write(key: 'userId', value: userData['_id']);
                                  await storage.write(key: 'userRole', value: userData['role']);
                                  debugPrint('✅ [LoginScreen] Datos guardados en FlutterSecureStorage');
                                  
                                  debugPrint('🔐 [LoginScreen] Llamando a setAuthData...');
                                  await authProvider.setAuthData(
                                    userData['token'],
                                    userData['_id'],
                                    userData['role'],
                                  );
                                  debugPrint('✅ [LoginScreen] setAuthData completado');
                                  
                                  // Verificar que el usuario se cargó correctamente
                                  if (authProvider.user == null) {
                                    throw Exception('No se pudo cargar el perfil del usuario. Intenta de nuevo.');
                                  }
                                  
                                  debugPrint('✅ [LoginScreen] Usuario cargado: ${authProvider.user?.email}');
                                  
                                  // Navegar a home
                                  if (mounted) {
                                    debugPrint('🚀 [LoginScreen] Navegando a MainNavigationScreen...');
                                    navigator.pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                                      (route) => false,
                                    );
                                    
                                    // Mensaje de bienvenida
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(userData['isNewUser'] == true 
                                          ? '¡Bienvenido ${userData['firstName']}! 🎉' 
                                          : '¡Hola de nuevo ${userData['firstName']}! 👋'),
                                        backgroundColor: colorScheme.tertiary,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                    debugPrint('✅ [LoginScreen] Navegación completada');
                                  }
                                } catch (e) {
                                  debugPrint('❌ [LoginScreen] Error durante el proceso de login: $e');
                                  debugPrint('❌ [LoginScreen] Stack trace: ${StackTrace.current}');
                                  
                                  // Limpiar datos si hay error
                                  try {
                                    await authProvider.logout();
                                  } catch (logoutError) {
                                    debugPrint('⚠️  [LoginScreen] Error al limpiar sesión: $logoutError');
                                  }
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al iniciar sesión: ${e.toString().replaceAll('Exception: ', '')}'),
                                        backgroundColor: colorScheme.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              },
                              onError: (error) {
                                // Determinar si es un error de correo no institucional
                                bool isEmailError = error.toLowerCase().contains('correo') || 
                                                  error.toLowerCase().contains('email') ||
                                                  error.toLowerCase().contains('institucional') ||
                                                  error.toLowerCase().contains('upt.pe') ||
                                                  error.toLowerCase().contains('permiten');
                                
                                String title = isEmailError ? 'Correo no válido' : 'Error de autenticación';
                                String message = isEmailError 
                                  ? 'Debes usar tu correo institucional @virtual.upt.pe para acceder a la aplicación.\n\nPuedes intentar con otro correo institucional.'
                                  : error;
                                
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    icon: Icon(
                                      isEmailError ? Icons.email : Icons.error, 
                                      size: 48, 
                                      color: isEmailError ? colorScheme.primary : colorScheme.error
                                    ),
                                    title: Text(
                                      title,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          if (isEmailError) ...[
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Requisitos:',
                                                        style: theme.textTheme.titleSmall?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '• Debes usar tu correo @virtual.upt.pe',
                                                    style: theme.textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    '• Verifica tu conexión a internet',
                                                    style: theme.textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    '• Asegúrate de pertenecer a la UPT',
                                                    style: theme.textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      if (isEmailError) ...[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                          },
                                          child: const Text('INTENTAR DE NUEVO'),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      FilledButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('ENTENDIDO'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Información de seguridad con diseño consistente
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.tertiary.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.verified_user_rounded,
                                      color: colorScheme.tertiary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Solo estudiantes UPT',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            color: colorScheme.onTertiaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Verifica tu identidad con tu correo institucional',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 40 : 32),
                    
                    // Footer con diseño consistente
                    Text(
                      '© 2024 RideUpt - UPT',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}







