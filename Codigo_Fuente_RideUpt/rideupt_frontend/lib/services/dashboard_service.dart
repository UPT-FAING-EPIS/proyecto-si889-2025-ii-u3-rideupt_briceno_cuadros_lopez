// services/dashboard_service.dart
import '../api/api_service.dart';

class DashboardService {
  static final ApiService _apiService = ApiService();

  // Obtener estadísticas del dashboard
  static Future<Map<String, dynamic>?> getDashboardStats(String token) async {
    try {
      final response = await _apiService.get('dashboard/stats', token);
      return response;
    } catch (e) {
      return null;
    }
  }

  // Obtener viajes recientes
  static Future<List<dynamic>?> getRecentTrips(String token, {int limit = 5}) async {
    try {
      final response = await _apiService.get('dashboard/recent-trips?limit=$limit', token);
      return response['trips'];
    } catch (e) {
      return null;
    }
  }
}
