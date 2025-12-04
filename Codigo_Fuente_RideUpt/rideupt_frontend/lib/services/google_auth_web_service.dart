// lib/services/google_auth_web_service.dart
// Servicio exclusivo para Google Sign-In en web
// Funciona tanto en local como en producción (Firebase Hosting)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
// Removed dart:html - using Uri.base instead for multiplatform support
import '../utils/app_config.dart';

class GoogleAuthWebService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Detecta si estamos en producción (Firebase Hosting) o desarrollo local
  bool get _isProduction {
    if (!kIsWeb) return false;
    try {
      final host = Uri.base.host;
      // Si el host contiene firebaseapp.com o web.app, estamos en producción
      return host.contains('firebaseapp.com') || 
             host.contains('web.app') ||
             (host.contains('rideupt') && !host.contains('localhost'));
    } catch (e) {
      // Si hay error, asumir producción
      return true;
    }
  }

  // URL del backend - usa AppConfig para obtener la URL correcta según el entorno
  String get _backendUrl {
    // Siempre usar AppConfig que ya maneja la detección correcta
    // En producción, AppConfig debería retornar https://rideupt.sytes.net
    // En local, retorna http://localhost:3000
    final url = AppConfig.socketUrl;
    
    if (kDebugMode) {
      debugPrint('🌐 [GoogleAuthWeb] Backend URL desde AppConfig: $url');
      debugPrint('🌐 [GoogleAuthWeb] Es Producción: $_isProduction');
    }
    
    return url;
  }

  /// Iniciar sesión con Google (versión web)
  /// Funciona tanto en local como en producción
  ///
  /// Retorna un Map con los datos del usuario si es exitoso, null si el usuario canceló
  /// Lanza una excepción si hay un error
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint('🌐 [GoogleAuthWeb] Iniciando Google Sign-In en web...');
        debugPrint('🌐 [GoogleAuthWeb] Backend URL: $_backendUrl');
        debugPrint('🌐 [GoogleAuthWeb] Es Web: $kIsWeb');
        debugPrint('🌐 [GoogleAuthWeb] Es Producción: $_isProduction');
        try {
          debugPrint('🌐 [GoogleAuthWeb] Current URL: ${Uri.base}');
          debugPrint('🌐 [GoogleAuthWeb] Current Host: ${Uri.base.host}');
        } catch (e) {
          debugPrint('⚠️  [GoogleAuthWeb] No se pudo obtener URL: $e');
        }
      }

      // Usar GoogleSignIn con el método que funciona en web
      // Primero intentar signInSilently, luego signIn si es necesario
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: <String>['email'],
      );

      // Limpiar cualquier sesión previa
      try {
        await googleSignIn.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️  [GoogleAuthWeb] Error al limpiar sesión previa (no crítico): $e');
        }
      }

      if (kDebugMode) {
        debugPrint('🔐 [GoogleAuthWeb] Intentando signInSilently primero...');
      }

      // Intentar signInSilently primero (puede funcionar si hay una sesión previa)
      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
      
      // Si signInSilently falla, usar signIn (aunque esté deprecado, aún funciona)
      if (googleUser == null) {
        if (kDebugMode) {
          debugPrint('🔐 [GoogleAuthWeb] signInSilently falló, usando signIn...');
        }
        googleUser = await googleSignIn.signIn();
      }
      
      if (googleUser == null) {
        if (kDebugMode) {
          debugPrint('⚠️  [GoogleAuthWeb] Usuario canceló el login');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('✅ [GoogleAuthWeb] Usuario de Google obtenido: ${googleUser.email}');
      }

      // Obtener autenticación - intentar múltiples veces si es necesario
      GoogleSignInAuthentication? googleAuth;
      int attempts = 0;
      const maxAttempts = 3;
      
      while (attempts < maxAttempts && googleAuth == null) {
        try {
          final auth = await googleUser.authentication;
          
          // Si tenemos idToken, usar esta autenticación
          if (auth.idToken != null) {
            googleAuth = auth;
            break;
          }
          
          // Si no tenemos idToken pero tenemos accessToken, esperar un poco y reintentar
          if (auth.accessToken != null && attempts < maxAttempts - 1) {
            if (kDebugMode) {
              debugPrint('⚠️  [GoogleAuthWeb] idToken es null, reintentando... (intento ${attempts + 1}/$maxAttempts)');
            }
            await Future.delayed(const Duration(milliseconds: 500));
            attempts++;
            continue;
          }
          
          // Si llegamos aquí y no tenemos idToken, guardar auth para intentar con accessToken
          googleAuth = auth;
        } catch (e) {
          if (e.toString().contains('People API') || 
              e.toString().contains('people.googleapis.com') ||
              e.toString().contains('SERVICE_DISABLED')) {
            throw Exception(
              'La People API de Google no está habilitada.\n\n'
              'Por favor, habilítala en:\n'
              'https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=619194261837\n\n'
              'Después de habilitarla, espera 2-3 minutos y vuelve a intentar.'
            );
          }
          
          if (attempts >= maxAttempts - 1) {
            rethrow;
          }
          
          attempts++;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      // Verificar que tenemos googleAuth
      if (googleAuth == null) {
        throw Exception('No se pudo obtener la autenticación de Google después de $maxAttempts intentos');
      }

      // Verificar idToken después de todos los intentos
      if (googleAuth.idToken == null) {
        if (kDebugMode) {
          debugPrint('❌ [GoogleAuthWeb] idToken es null después de todos los intentos');
          debugPrint('   AccessToken disponible: ${googleAuth.accessToken != null}');
        }
        
        // Si tenemos accessToken pero no idToken, intentar autenticar solo con accessToken
        if (googleAuth.accessToken != null) {
          if (kDebugMode) {
            debugPrint('⚠️  [GoogleAuthWeb] Intentando autenticación solo con accessToken...');
          }
          
          try {
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
            );
            
            final userCredential = await _auth.signInWithCredential(credential);
            
            if (userCredential.user != null) {
              if (kDebugMode) {
                debugPrint('✅ [GoogleAuthWeb] Autenticado con Firebase usando solo accessToken');
              }
              
              final String? firebaseIdToken = await userCredential.user!.getIdToken();
              if (firebaseIdToken != null) {
                return await _sendToBackend(firebaseIdToken);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ [GoogleAuthWeb] Error al autenticar con solo accessToken: $e');
            }
          }
        }
        
        throw Exception(
          'No se pudo obtener el token de autenticación de Google (idToken es null).\n\n'
          'Esto es un problema conocido con GoogleSignIn en web.\n\n'
          'Soluciones:\n'
          '1. Asegúrate de que la People API esté habilitada\n'
          '2. Verifica que el OAuth Client ID esté correctamente configurado\n'
          '3. Intenta en un navegador diferente o en modo incógnito\n'
          '4. Limpia la caché del navegador y vuelve a intentar'
        );
      }

      if (kDebugMode) {
        debugPrint('✅ [GoogleAuthWeb] idToken obtenido de Google');
      }

      // Crear credencial y autenticar con Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('No se pudo autenticar con Firebase');
      }

      if (kDebugMode) {
        debugPrint('✅ [GoogleAuthWeb] Autenticado con Firebase');
        debugPrint('   📧 Email: ${userCredential.user!.email}');
      }

      // Obtener token de Firebase para el backend
      final String? firebaseIdToken = await userCredential.user!.getIdToken();

      if (firebaseIdToken == null) {
        throw Exception('No se pudo obtener el token de Firebase');
      }

      if (kDebugMode) {
        debugPrint('✅ [GoogleAuthWeb] Token de Firebase obtenido');
      }

      return await _sendToBackend(firebaseIdToken);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GoogleAuthWeb] Error de Firebase: ${e.code} - ${e.message}');
      }

      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception('Ya existe una cuenta con este email usando otro método de inicio de sesión');
        case 'invalid-credential':
          throw Exception('Las credenciales son inválidas');
        case 'operation-not-allowed':
          throw Exception('Inicio de sesión con Google no está habilitado');
        case 'user-disabled':
          throw Exception('Esta cuenta ha sido deshabilitada');
        case 'user-not-found':
          throw Exception('No se encontró una cuenta con este email');
        default:
          throw Exception('Error de autenticación: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GoogleAuthWeb] Error: $e');
      }
      rethrow;
    }
  }

  /// Enviar token al backend y obtener datos del usuario
  Future<Map<String, dynamic>> _sendToBackend(String firebaseIdToken) async {
    final backendUrl = _backendUrl;
    final fullUrl = '$backendUrl/api/auth/google';
    
    if (kDebugMode) {
      debugPrint('✅ [GoogleAuthWeb] Token de Firebase obtenido, enviando al backend...');
      debugPrint('🌐 [GoogleAuthWeb] URL del backend: $fullUrl');
      debugPrint('🌐 [GoogleAuthWeb] Es Web: $kIsWeb');
      debugPrint('🌐 [GoogleAuthWeb] Current URL: ${Uri.base}');
    }

    try {
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'idToken': firebaseIdToken}),
      );

      if (kDebugMode) {
        debugPrint('📥 [GoogleAuthWeb] Respuesta del backend: ${response.statusCode}');
        debugPrint('📥 [GoogleAuthWeb] URL completa: $fullUrl');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (kDebugMode) {
          debugPrint('✅ [GoogleAuthWeb] Login exitoso');
          debugPrint('   📧 Email: ${data['email']}');
          debugPrint('   🎭 Rol: ${data['role']}');
          debugPrint('   👑 isAdmin: ${data['isAdmin'] ?? false}');
        }

        return data;
      } else {
        String errorMessage = 'Error del servidor';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Error del servidor';
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [GoogleAuthWeb] No se pudo parsear el error: $e');
          }
          errorMessage = 'Error del servidor (${response.statusCode})';
        }
        
        if (kDebugMode) {
          debugPrint('❌ [GoogleAuthWeb] Error del servidor: ${response.statusCode}');
          debugPrint('❌ [GoogleAuthWeb] Mensaje: $errorMessage');
          debugPrint('❌ [GoogleAuthWeb] Body: ${response.body}');
        }
        
        await _auth.signOut();
        await GoogleSignIn().signOut();
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      // Error de conexión (CORS, Mixed Content, o servidor inaccesible)
      if (kDebugMode) {
        debugPrint('❌ [GoogleAuthWeb] Error de conexión: $e');
      }
      
      String errorMessage = 'No se pudo conectar al servidor. ';
      
      // Detectar si es Mixed Content (HTTPS -> HTTP)
      if (kIsWeb) {
        try {
          final currentScheme = Uri.base.scheme;
          if (currentScheme == 'https' && backendUrl.startsWith('http://')) {
            errorMessage += '\n\n⚠️ PROBLEMA DE MIXED CONTENT:\n'
                'Tu aplicación está en HTTPS (${Uri.base.host}) pero el backend está en HTTP.\n'
                'Los navegadores bloquean peticiones HTTP desde páginas HTTPS por seguridad.\n\n'
                'El backend debe usar HTTPS. Verifica: https://rideupt.sytes.net/health';
          } else {
            errorMessage += '\n\nPosibles causas:\n'
                '1. El servidor no está accesible desde internet\n'
                '   - Verifica: $backendUrl/health\n'
                '2. Problema de CORS\n'
                '3. Firewall bloqueando el puerto';
          }
        } catch (_) {
          errorMessage += '\n\nVerifica que el servidor esté accesible desde internet.';
        }
      }
      
      await _auth.signOut();
      await GoogleSignIn().signOut();
      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GoogleAuthWeb] Error inesperado: $e');
      }
      
      // Si es un error de conexión genérico, dar mensaje más específico
      final errorString = e.toString();
      if (errorString.contains('Failed to fetch') || 
          errorString.contains('NetworkError') ||
          errorString.contains('Network request failed')) {
        String errorMessage = 'No se pudo conectar al servidor. ';
        
        if (kIsWeb && Uri.base.scheme == 'https' && backendUrl.startsWith('http://')) {
          errorMessage += '\n\n⚠️ PROBLEMA DE MIXED CONTENT:\n'
              'Tu aplicación está en HTTPS pero el backend está en HTTP.\n'
              'Los navegadores bloquean peticiones HTTP desde páginas HTTPS.\n\n'
              'El backend debe usar HTTPS: https://rideupt.sytes.net';
        }
        
        await _auth.signOut();
        await GoogleSignIn().signOut();
        throw Exception(errorMessage);
      }
      
      rethrow;
    }
  }

  /// Cerrar sesión de Firebase y Google
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        debugPrint('🚪 [GoogleAuthWeb] Cerrando sesión...');
      }

      await Future.wait([
        _auth.signOut(),
        GoogleSignIn().signOut(),
      ]);

      if (kDebugMode) {
        debugPrint('✅ [GoogleAuthWeb] Sesión cerrada');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GoogleAuthWeb] Error al cerrar sesión: $e');
      }
      rethrow;
    }
  }

  /// Verificar si hay un usuario autenticado actualmente
  User? get currentUser => _auth.currentUser;

  /// Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
