// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/user.dart';
import 'package:rideupt_app/services/notification_service.dart';
import 'package:rideupt_app/services/socket_service.dart';
import 'package:rideupt_app/services/chat_service.dart';
import 'package:rideupt_app/services/google_auth_service.dart';
import 'package:rideupt_app/services/rating_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _token;
  User? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Esta función está diseñada para recibir la PROMESA (Future) de una autenticación.
  Future<bool> _authenticate(Future<dynamic> authFuture) async {
    _setLoading(true);
    _errorMessage = '';
    try {
      final response = await authFuture as Map<String, dynamic>;
      _token = response['token'];
      await _getUserProfile();

      await _registerDeviceForNotifications();
      SocketService().connect(_token!);
      
      // Configurar el token en los servicios
      RatingService.setToken(_token!);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }
  
  /// Extrae el mensaje de error de forma consistente
  String _extractErrorMessage(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('HttpException: ')) {
      return errorString.replaceAll('HttpException: ', '');
    }
    if (errorString.contains('SocketException: ')) {
      return 'Error de conexión. Verifica tu conexión a Internet.';
    }
    if (errorString.contains('TimeoutException')) {
      return 'Tiempo de espera agotado. Intenta de nuevo.';
    }
    if (errorString.contains('FormatException')) {
      return 'Error al procesar la respuesta del servidor.';
    }
    return errorString.replaceAll('Exception: ', '');
  }

  Future<bool> login(String email, String password) async {
    // Limpiar errores previos antes de intentar login
    _errorMessage = '';
    return _authenticate(_apiService.postPublic('auth/login', {'email': email, 'password': password}));
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    // Limpiar errores previos antes de intentar registro
    _errorMessage = '';
    return _authenticate(_apiService.postPublic('auth/register', userData));
  }

  Future<void> _getUserProfile() async {
    if (_token == null) {
      debugPrint('⚠️  [AuthProvider] No hay token para obtener perfil');
      return;
    }
    
    try {
      debugPrint('📥 [AuthProvider] Obteniendo perfil del usuario...');
      final userData = await _apiService.get('users/profile', _token!);
      
      if (userData == null) {
        debugPrint('⚠️  [AuthProvider] Respuesta vacía del servidor');
        _errorMessage = 'No se pudo obtener el perfil del usuario.';
        notifyListeners();
        return;
      }
      
      debugPrint('✅ [AuthProvider] Perfil obtenido: ${userData['email'] ?? 'N/A'}');
      debugPrint('   📷 Foto: ${userData['profilePhoto'] ?? 'N/A'}');
      
      _user = User.fromJson(userData);
      notifyListeners();
      
      debugPrint('✅ [AuthProvider] Usuario actualizado en el provider');
    } catch (e) {
      // Solo cerrar sesión si es un error de autenticación (401, 403)
      // No cerrar sesión por errores de red o timeout
      final errorString = e.toString();
      debugPrint('❌ [AuthProvider] Error al obtener perfil: $errorString');
      
      if (errorString.contains('401') || 
          errorString.contains('403') || 
          errorString.contains('Unauthorized') ||
          errorString.contains('Forbidden')) {
        debugPrint('❌ [AuthProvider] Error de autenticación al obtener perfil, cerrando sesión');
        logout();
      } else {
        debugPrint('⚠️  [AuthProvider] Error al obtener perfil (no crítico): $e');
        // No cerrar sesión, solo notificar el error
        _errorMessage = 'Error al cargar el perfil. Intenta recargar la página.';
        notifyListeners();
      }
    }
  }

  /// Refresca el perfil del usuario desde el servidor
  Future<void> refreshUserProfile() async {
    await _getUserProfile();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return false;
    }
    _token = prefs.getString('token');
    if (_token == null) return false;
    
    // Configurar el token en RatingService cuando se restaura desde SharedPreferences
    RatingService.setToken(_token!);
    
    try {
      await _getUserProfile();
      // La comprobación de isAuthenticated se basa en si _getUserProfile tuvo éxito
      return isAuthenticated;
    } catch (e) {
      // Si falla el auto-login, limpiar el token inválido
      _token = null;
      _user = null;
      await prefs.remove('token');
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint('🚪 Cerrando sesión...');
    
    // Desconectar sockets
    try {
      SocketService().disconnect();
      ChatService.getInstance().disconnect();
    } catch (e) {
      debugPrint('Error al desconectar sockets: $e');
    }
    
    // Cerrar sesión de Google (si está usando Google Sign-In)
    try {
      final googleAuthService = GoogleAuthService();
      await googleAuthService.signOut();
      debugPrint('✅ Sesión de Google cerrada');
    } catch (e) {
      debugPrint('⚠️  No había sesión de Google activa');
    }
    
    // Limpiar datos locales
    _token = null;
    _user = null;
    
    // Limpiar el token de los servicios
    RatingService.setToken('');
    
    // Limpiar storage (preservando onboarding_completed)
    final prefs = await SharedPreferences.getInstance();
    // Guardar el estado del onboarding antes de limpiar
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    await prefs.clear(); // Limpiar todo el storage
    // Restaurar el estado del onboarding después de limpiar
    await prefs.setBool('onboarding_completed', onboardingCompleted);
    
    notifyListeners();
    debugPrint('✅ Sesión cerrada completamente');
  }

  Future<bool> updateDriverProfile(Map<String, dynamic> vehicleData) async {
    _setLoading(true);
    if (_token == null) {
      _errorMessage = "No estás autenticado.";
      _setLoading(false);
      return false;
    }

    try {
      await _apiService.put('users/driver-profile', _token!, vehicleData);
      // Refrescar los datos del usuario para obtener el nuevo rol y vehículo
      await _getUserProfile();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Reenviar solicitud de conductor (cuando fue rechazada)
  Future<bool> resubmitDriverApplication() async {
    _setLoading(true);
    if (_token == null) {
      _errorMessage = "No estás autenticado.";
      _setLoading(false);
      return false;
    }

    try {
      await _apiService.post('users/resubmit-driver-application', _token!, {});
      // Refrescar los datos del usuario para obtener el nuevo estado
      await _getUserProfile();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Cambiar modo del usuario (conductor/pasajero)
  Future<bool> switchUserMode(String mode) async {
    _setLoading(true);
    if (_token == null) {
      _errorMessage = "No estás autenticado.";
      _setLoading(false);
      return false;
    }

    try {
      await _apiService.put('users/switch-mode', _token!, {'mode': mode});
      
      // Refrescar los datos del usuario desde el servidor para obtener el nuevo rol
      // Esto asegura que todos los datos estén actualizados correctamente, incluyendo calificaciones
      await _getUserProfile();
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> _registerDeviceForNotifications() async {
    if (_token == null) return;
    try {
      final fcmToken = await NotificationService().getFcmToken();
      if (fcmToken != null) {
        await _apiService.put('users/fcm-token', _token!, {'fcmToken': fcmToken});
        debugPrint("Token FCM registrado en el backend.");
      }
    } catch (e) {
      debugPrint("Error al registrar el token FCM: $e");
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Método para limpiar errores manualmente
  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }

  // Método para limpiar completamente el estado de autenticación
  void clearAuthState() {
    _token = null;
    _user = null;
    _errorMessage = '';
    _isLoading = false;
    notifyListeners();
  }

  // ==========================================
  // GOOGLE SIGN-IN
  // ==========================================
  /// Establece los datos de autenticación directamente (para Google Sign-In)
  /// Este método se usa cuando el usuario ya fue autenticado por Firebase
  Future<void> setAuthData(String token, String userId, String role) async {
    debugPrint('🔐 [AuthProvider] setAuthData iniciado');
    _token = token;
    
    // Configurar el token en RatingService
    RatingService.setToken(token);
    
    // Guardar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    debugPrint('✅ [AuthProvider] Token guardado en SharedPreferences');
    
    // Obtener perfil del usuario - ESTO ES CRÍTICO
    debugPrint('📥 [AuthProvider] Obteniendo perfil del usuario...');
    try {
      await _getUserProfile();
      debugPrint('✅ [AuthProvider] Perfil obtenido exitosamente');
      
      // Verificar que el usuario se cargó correctamente
      if (_user == null) {
        debugPrint('⚠️  [AuthProvider] Usuario es null después de _getUserProfile');
        throw Exception('No se pudo cargar el perfil del usuario');
      }
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error al obtener perfil después de setAuthData: $e');
      // Si falla obtener el perfil, no podemos continuar
      _token = null;
      _user = null;
      await prefs.remove('token');
      notifyListeners();
      rethrow; // Relanzar el error para que el login screen lo maneje
    }
    
    // Registrar para notificaciones (no crítico, puede fallar)
    try {
      await _registerDeviceForNotifications();
      debugPrint('✅ [AuthProvider] Notificaciones registradas');
    } catch (e) {
      debugPrint('⚠️  [AuthProvider] Error al registrar notificaciones (no crítico): $e');
    }
    
    // Conectar socket (no crítico, puede fallar)
    try {
      SocketService().connect(token);
      debugPrint('✅ [AuthProvider] Socket conectado');
    } catch (e) {
      debugPrint('⚠️  [AuthProvider] Error al conectar socket (no crítico): $e');
    }
    
    notifyListeners();
    debugPrint('✅ [AuthProvider] setAuthData completado exitosamente');
  }

  // Método para cambiar el rol del usuario
  // @deprecated Usar switchUserMode en su lugar, que incluye validaciones del backend
  Future<void> updateUserRole(String newRole) async {
    if (_user == null) return;
    
    try {
      _setLoading(true);
      
      // Actualizar el rol en el backend
      await _apiService.updateUserRole(_token!, newRole);
      
      // Actualizar el usuario local usando copyWith
      _user = _user!.copyWith(role: newRole);
      
      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', newRole);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
}