// lib/services/rating_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../widgets/rating_widget.dart';
import '../utils/app_config.dart';
import '../providers/auth_provider.dart';

class RatingService {
  static String get baseUrl => AppConfig.baseUrl;
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // Obtener token del AuthProvider si está disponible en el contexto
  static String? _getTokenFromContext(BuildContext? context) {
    if (context != null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return authProvider.token;
      } catch (e) {
        // Si no hay provider disponible, usar el token estático
        return _token;
      }
    }
    return _token;
  }

  static Map<String, String> _getHeaders(BuildContext? context) {
    final token = _getTokenFromContext(context) ?? _token;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Crear una nueva calificación
  static Future<Map<String, dynamic>> createRating({
    required String ratedId,
    required String tripId,
    required int rating,
    String? comment,
    required String ratingType,
    BuildContext? context,
  }) async {
    try {
      final headers = _getHeaders(context);
      
      if (!headers.containsKey('Authorization')) {
        return {
          'success': false,
          'message': 'No autorizado: no se proporcionó un token',
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/ratings'),
        headers: headers,
        body: jsonEncode({
          'ratedId': ratedId,
          'tripId': tripId,
          'rating': rating,
          'comment': comment,
          'ratingType': ratingType,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      } else {
        // Manejar diferentes formatos de respuesta de error
        String errorMessage = 'Error al crear calificación';
        if (data is Map<String, dynamic>) {
          if (data.containsKey('message')) {
            errorMessage = data['message'];
          } else if (data.containsKey('error')) {
            errorMessage = data['error'];
          } else if (data.containsKey('errors') && data['errors'] is List) {
            final errors = data['errors'] as List;
            if (errors.isNotEmpty) {
              errorMessage = errors[0].toString();
            }
          }
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  /// Obtener calificaciones de un usuario
  static Future<Map<String, dynamic>> getUserRatings({
    required String userId,
    int page = 1,
    int limit = 10,
    BuildContext? context,
  }) async {
    try {
      final headers = _getHeaders(context);
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/user/$userId?page=$page&limit=$limit'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener calificaciones',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener estadísticas de calificaciones de un usuario
  static Future<Map<String, dynamic>> getUserRatingStats({
    required String userId,
    BuildContext? context,
  }) async {
    try {
      final headers = _getHeaders(context);
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/user/$userId/stats'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener estadísticas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener calificaciones que el usuario ha dado
  static Future<Map<String, dynamic>> getRatingsGiven({
    int page = 1,
    int limit = 10,
    BuildContext? context,
  }) async {
    try {
      final headers = _getHeaders(context);
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/given?page=$page&limit=$limit'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener calificaciones dadas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Mostrar diálogo para calificar
  static Future<void> showRatingDialog({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Function(int rating, String? comment) onSubmit,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => RatingInputDialog(
        title: title,
        subtitle: subtitle,
        onSubmit: onSubmit,
      ),
    );
  }

  /// Calificar a un conductor
  static Future<bool> rateDriver({
    required String driverId,
    required String tripId,
    required int rating,
    String? comment,
  }) async {
    final result = await createRating(
      ratedId: driverId,
      tripId: tripId,
      rating: rating,
      comment: comment,
      ratingType: 'driver',
    );
    return result['success'] ?? false;
  }

  /// Calificar a un pasajero
  static Future<bool> ratePassenger({
    required String passengerId,
    required String tripId,
    required int rating,
    String? comment,
  }) async {
    final result = await createRating(
      ratedId: passengerId,
      tripId: tripId,
      rating: rating,
      comment: comment,
      ratingType: 'passenger',
    );
    return result['success'] ?? false;
  }

  /// Verificar si se puede calificar a un usuario (si ya se calificó)
  static Future<Map<String, dynamic>> canRateUser({
    required String ratedId,
    required String tripId,
    required String ratingType,
    BuildContext? context,
  }) async {
    try {
      final headers = _getHeaders(context);
      
      if (!headers.containsKey('Authorization')) {
        return {
          'success': false,
          'canRate': false,
          'alreadyRated': false,
          'message': 'No autorizado: no se proporcionó un token',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/can-rate/$ratedId/$tripId/$ratingType'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'canRate': data['data']?['canRate'] ?? false,
          'alreadyRated': data['data']?['alreadyRated'] ?? false,
        };
      } else {
        return {
          'success': false,
          'canRate': false,
          'alreadyRated': false,
          'message': data['message'] ?? 'Error al verificar calificación',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'canRate': false,
        'alreadyRated': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
