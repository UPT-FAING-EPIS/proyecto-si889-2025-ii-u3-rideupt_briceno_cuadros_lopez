import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Estructura que contiene el marcador y su anchor
class MarkerData {
  final BitmapDescriptor icon;
  final Offset anchor;

  MarkerData({required this.icon, required this.anchor});
}

/// Crea un marcador personalizado con un punto verde para el origen
/// Centro negro con aro verde fosforescente (más grande y brillante)
Future<BitmapDescriptor> createGreenMarker() async {
  return await _createCustomMarker(
    const Color(0xFF00FFAA), // Verde fosforescente muy brillante
    Colors.black, // Centro negro
    isLarge: true, // Marcador grande para inicio/fin
  );
}

/// Crea un marcador personalizado con un punto rojo para el destino
/// Centro negro con aro rojo fosforescente (más grande y brillante)
Future<BitmapDescriptor> createRedMarker() async {
  return await _createCustomMarker(
    const Color(0xFFFF0044), // Rojo fosforescente muy brillante
    Colors.black, // Centro negro
    isLarge: true, // Marcador grande para inicio/fin
  );
}

/// Crea un marcador personalizado para waypoints (puntos intermedios)
/// Centro negro con aro amarillo fosforescente oscuro
Future<BitmapDescriptor> createYellowMarker() async {
  return await _createCustomMarker(
    const Color(0xFFFFAA00), // Amarillo fosforescente oscuro/ámbar
    Colors.black, // Centro negro
    isLarge: false, // Marcador normal para waypoints
  );
}

/// Obtiene el anchor correcto para un marcador grande (inicio/fin)
Offset getLargeMarkerAnchor() {
  // El anchor debe estar en el centro del marcador (0.5, 0.5)
  // pero ajustado para que el punto central negro esté en la posición correcta
  const double canvasSize = 48.0; // Tamaño del canvas
  const double center = canvasSize / 2;
  return Offset(center / canvasSize, center / canvasSize);
}

/// Obtiene el anchor correcto para un marcador pequeño (waypoint)
Offset getSmallMarkerAnchor() {
  const double canvasSize = 28.0; // Tamaño del canvas
  const double center = canvasSize / 2;
  return Offset(center / canvasSize, center / canvasSize);
}

/// Crea un marcador personalizado con centro negro y aro de color fosforescente
Future<BitmapDescriptor> _createCustomMarker(
  Color ringColor,
  Color centerColor, {
  bool isLarge = false,
}) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  
  // Tamaños según si es marcador grande (inicio/fin) o normal (waypoint)
  // Reducidos para que se vean más proporcionados
  final double centerSize = isLarge ? 12.0 : 6.0; // Centro negro (más grande para inicio/fin)
  final double ringSize = isLarge ? 28.0 : 16.0; // Aro exterior (más grande para inicio/fin)
  final double borderSize = isLarge ? 36.0 : 20.0; // Borde exterior más claro (más grande)
  final double canvasSize = isLarge ? 48.0 : 28.0; // Tamaño total del canvas (más grande)
  final double center = canvasSize / 2;

  // Pintura para el aro fosforescente (más grueso y brillante para marcadores grandes)
  final Paint ringPaint = Paint()
    ..color = ringColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = isLarge ? 4.0 : 3.0
    ..strokeCap = StrokeCap.round;

  // Pintura para el borde exterior del aro (más claro y brillante)
  final Paint borderPaint = Paint()
    ..color = ringColor.withValues(alpha: isLarge ? 0.4 : 0.25)
    ..style = PaintingStyle.stroke
    ..strokeWidth = isLarge ? 8.0 : 5.0;

  // Pintura para el centro negro
  final Paint centerPaint = Paint()..color = centerColor;

  // Dibujar borde exterior del aro (más suave y brillante)
  canvas.drawCircle(
    Offset(center, center),
    borderSize / 2,
    borderPaint,
  );

  // Dibujar aro fosforescente (más brillante)
  canvas.drawCircle(
    Offset(center, center),
    ringSize / 2,
    ringPaint,
  );

  // Dibujar centro negro
  canvas.drawCircle(
    Offset(center, center),
    centerSize / 2,
    centerPaint,
  );

  final picture = pictureRecorder.endRecording();
  final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
}

