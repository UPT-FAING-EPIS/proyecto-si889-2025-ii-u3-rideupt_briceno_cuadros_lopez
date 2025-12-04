import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Decodifica un polyline codificado de Google Maps
List<LatLng> decodePolyline(String encoded) {
  List<LatLng> poly = [];
  int index = 0;
  int len = encoded.length;
  int lat = 0;
  int lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    poly.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return poly;
}

/// Obtiene la ruta real entre dos puntos usando Google Directions API
Future<List<LatLng>?> getRoute(
  LatLng origin,
  LatLng destination, {
  String? apiKey,
  List<LatLng>? waypoints,
}) async {
  try {
    // Usar la API key de Google Maps (la misma que se usa en location_picker_screen)
    final key = apiKey ?? 'AIzaSyAqn3zQNpXL9VgtWpjVBInVJWj9KN6LEvk';
    
    // Construir URL
    String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$key'
        '&language=es';
    
    // Agregar waypoints si existen
    if (waypoints != null && waypoints.isNotEmpty) {
      String waypointsStr = waypoints
          .map((w) => '${w.latitude},${w.longitude}')
          .join('|');
      url += '&waypoints=$waypointsStr';
    }

    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final overviewPolyline = route['overview_polyline'];
        final encodedPolyline = overviewPolyline['points'];
        
        return decodePolyline(encodedPolyline);
      }
    }
    
    return null;
  } catch (e) {
    // Si falla, retornar null para usar línea recta como fallback
    return null;
  }
}


