// lib/screens/auth/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_panel_screen.dart';
import '../../services/google_auth_web_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final GoogleAuthWebService _googleAuthWebService = GoogleAuthWebService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        debugPrint('🔐 [ADMIN LOGIN] Iniciando Google Sign-In...');
      }

      final result = await _googleAuthWebService.signInWithGoogle();

      if (result == null) {
        // Usuario canceló
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      await _handleGoogleSignInSuccess(result);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ADMIN LOGIN] Error: $e');
      }
      _handleGoogleSignInError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignInSuccess(Map<String, dynamic> result) async {
    if (kDebugMode) {
      debugPrint('✅ [ADMIN LOGIN] Google Sign-In exitoso');
      debugPrint('   📧 Email: ${result['email']}');
      debugPrint('   🎭 Rol: ${result['role']}');
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Configurar los datos de autenticación
    await authProvider.setAuthData(
      result['token'],
      result['_id'],
      result['role'],
    );

    if (mounted) {
      // Verificar que sea admin
      final user = authProvider.user;
      if (user?.isAdmin == true) {
        // Navegar al panel administrativo
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        );
      } else {
        // No es admin, cerrar sesión y mostrar error
        await authProvider.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Acceso denegado. Solo administradores pueden acceder al panel web.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _handleGoogleSignInError(String error) {
    if (kDebugMode) {
      debugPrint('❌ [ADMIN LOGIN] Error en Google Sign-In: $error');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🔐 [AdminLoginScreen] Construyendo widget');
    }
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 40 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      // Logo/Icono
                      Icon(
                        Icons.admin_panel_settings,
                        size: isTablet ? 100 : 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      
                      // Título
                      Text(
                        'Panel Administrativo',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RideUPT - UPT',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // Card de login
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
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
                              // Banner informativo
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.security, color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Acceso exclusivo para administradores',
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
                              const SizedBox(height: 24),
                              
                              Text(
                                'Iniciar Sesión',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Usa tu cuenta de Google institucional',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              
                              // Información sobre el login
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Debes usar tu cuenta de Google asociada a un correo institucional @virtual.upt.pe o @upt.pe con permisos de administrador.',
                                        style: TextStyle(
                                          color: Colors.blue[900],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Botón de Google Sign-In (web exclusivo)
                              _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _handleGoogleSignIn,
                                        icon: Image.network(
                                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                          width: 24,
                                          height: 24,
                                          errorBuilder: (context, error, stackTrace) {
                                            // Si no se puede cargar, usar icono de Material
                                            return const Icon(
                                              Icons.login,
                                              size: 24,
                                              color: Colors.black87,
                                            );
                                          },
                                        ),
                                        label: const Text(
                                          'Iniciar sesión con Google',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Copyright
                      Text(
                        '© 2025 RideUpt - UPT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
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
      );
  }
}

