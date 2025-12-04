import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/app_config.dart';

// HttpException personalizado para web
class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}

/// Servicio de API mejorado con mejor manejo de errores y timeouts
class ApiService {
  final String _baseUrl = AppConfig.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 20);

  /// Maneja las peticiones HTTP con mejor manejo de errores
  Future<dynamic> _handleRequest(
    Future<http.Response> request, {
    int retryCount = 0,
  }) async {
    try {
      if (kDebugMode && retryCount == 0) {
        debugPrint('⏳ [API] Enviando petición (timeout: ${_timeoutDuration.inSeconds}s)...');
      }
      
      final response = await request.timeout(_timeoutDuration);
      
      if (kDebugMode) {
        debugPrint('📥 [API] Respuesta recibida: ${response.statusCode}');
        debugPrint('📄 [API] Headers: ${response.headers}');
      }
      
      // Manejar respuesta vacía
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return null;
        }
        throw HttpException('Respuesta vacía del servidor');
      }

      dynamic responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        throw HttpException('Error al procesar la respuesta del servidor');
      }

      // Respuestas exitosas
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      }

      // Manejar errores de validación
      if (responseData is Map<String, dynamic>) {
        if (responseData['errors'] is List && (responseData['errors'] as List).isNotEmpty) {
          final firstError = responseData['errors'][0];
          final errorMessage = firstError is Map 
              ? (firstError['msg'] ?? firstError['message'] ?? 'Error de validación')
              : 'Error de validación';
          throw HttpException(errorMessage);
        }
        
        // Mensaje de error del backend
        final errorMessage = responseData['message'] ?? 
                            responseData['error'] ?? 
                            'Ocurrió un error desconocido';
        throw HttpException(errorMessage);
      }

      // Error genérico
      throw HttpException('Error del servidor (${response.statusCode})');
      
    } on HttpException catch (e) {
      throw HttpException(e.message);
    } on FormatException {
      throw HttpException('Error al procesar la respuesta del servidor');
    } catch (e) {
      if (e is HttpException) rethrow;
      
      // Manejar errores de red específicos
      final errorString = e.toString();
      
      if (kDebugMode) {
        debugPrint('🔴 [API] Error capturado: $errorString');
      }
      
      if (errorString.contains('Failed to fetch') || 
          errorString.contains('NetworkError') ||
          errorString.contains('Network request failed')) {
        // En web, esto puede ser CORS, mixed content, o servidor inaccesible
        String errorMsg = 'No se pudo conectar al servidor. ';
        
        if (kIsWeb) {
          errorMsg += 'Posibles causas:\n'
                     '1. El servidor no está accesible desde internet\n'
                     '2. Problema de CORS (verifica configuración del servidor)\n'
                     '3. Mixed Content (HTTPS intentando acceder a HTTP)\n'
                     '4. Firewall bloqueando el puerto 3000';
        } else {
          errorMsg += 'Verifica que el servidor esté en ejecución y accesible.';
        }
        
        throw HttpException(errorMsg);
      }
      
      throw HttpException('Error inesperado: ${e.toString()}');
    }
  }

  // Petición POST pública (sin token)
  Future<dynamic> postPublic(String endpoint, Map<String, dynamic> data) async {
    final url = '$_baseUrl/$endpoint';
    
    if (kDebugMode) {
      debugPrint('🌐 [API] POST $url');
      debugPrint('📦 [API] Body: ${json.encode(data)}');
      debugPrint('🖥️  [API] Es Web: $kIsWeb');
    }
    
    try {
      final uri = Uri.parse(url);
      if (kDebugMode) {
        debugPrint('🔗 [API] URI parseada: ${uri.toString()}');
        debugPrint('🔗 [API] Host: ${uri.host}, Port: ${uri.port}, Scheme: ${uri.scheme}');
      }
      
      final response = await _handleRequest(
        http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(data),
        ),
      );
      
      if (kDebugMode) {
        debugPrint('✅ [API] Respuesta exitosa');
      }
      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [API] Error: $e');
        debugPrint('🔗 [API] URL intentada: $url');
        debugPrint('📋 [API] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
  
  /// Headers comunes para peticiones autenticadas
  Map<String, String> _getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// Petición POST con token de autenticación
  Future<dynamic> post(String endpoint, String token, Map<String, dynamic> data) async {
    return _handleRequest(
      http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _getAuthHeaders(token),
        body: json.encode(data),
      ),
    );
  }

  /// Petición GET con token de autenticación
  Future<dynamic> get(String endpoint, String token) async {
    return _handleRequest(
      http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _getAuthHeaders(token),
      ),
    );
  }

  /// Petición PUT con token de autenticación
  Future<dynamic> put(String endpoint, String token, Map<String, dynamic> data) async {
    return _handleRequest(
      http.put(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _getAuthHeaders(token),
        body: json.encode(data),
      ),
    );
  }

  /// Petición DELETE con token de autenticación
  /// Si hay data, usa PUT para enviar el body (el backend espera PUT para cancelar con motivo)
  Future<dynamic> delete(String endpoint, String token, {Map<String, dynamic>? data}) async {
    if (data != null && data.isNotEmpty) {
      // Usar PUT si hay datos para enviar (como cancellationReason)
      return _handleRequest(
        http.put(
          Uri.parse('$_baseUrl/$endpoint'),
          headers: _getAuthHeaders(token),
          body: json.encode(data),
        ),
      );
    }
    
    return _handleRequest(
      http.delete(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _getAuthHeaders(token),
      ),
    );
  }

  // Método para actualizar el rol del usuario
  Future<dynamic> updateUserRole(String token, String newRole) async {
    return _handleRequest(
      http.put(
        Uri.parse('$_baseUrl/users/role'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'role': newRole}),
      ),
    );
  }

  /// Petición POST multipart para subir archivos (imágenes)
  Future<dynamic> postMultipart(
    String endpoint,
    String token,
    dynamic imageFile, // Usar dynamic para compatibilidad web/móvil
    Map<String, String> fields,
  ) async {
    try {
      // Construir URL completa
      final url = '$_baseUrl/$endpoint';
      if (kDebugMode) {
        debugPrint('📤 [ApiService] Subiendo archivo a: $url');
        debugPrint('📤 [ApiService] Base URL: $_baseUrl');
        debugPrint('📤 [ApiService] Endpoint: $endpoint');
      }
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      // Agregar headers de autenticación
      request.headers['Authorization'] = 'Bearer $token';

      // Agregar campos de texto
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Agregar archivo de imagen (compatible con web y móvil)
      if (kIsWeb) {
        // En web, imageFile es un Uint8List o similar
        final bytes = imageFile as List<int>;
        final multipartFile = http.MultipartFile.fromBytes(
          'imagen',
          bytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      } else {
        // En móvil, imageFile es un File
        final file = imageFile as dynamic; // File en móvil
        final fileStream = file.openRead();
        final fileLength = await file.length();
        final multipartFile = http.MultipartFile(
          'imagen',
          fileStream,
          fileLength,
          filename: file.path.split('/').last,
          contentType: MediaType('image', file.path.split('.').last == 'png' ? 'png' : 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      // Enviar petición
      final streamedResponse = await request.send().timeout(_timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      // Procesar respuesta usando el mismo manejo de errores
      return await _handleRequest(Future.value(response));
    } on HttpException catch (e) {
      throw HttpException(e.message);
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Error inesperado al subir archivo: ${e.toString()}');
    }
  }
}