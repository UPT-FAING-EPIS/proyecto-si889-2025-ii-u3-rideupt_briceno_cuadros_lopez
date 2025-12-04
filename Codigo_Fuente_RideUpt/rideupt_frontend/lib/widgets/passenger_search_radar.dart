// lib/widgets/passenger_search_radar.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class PassengerSearchRadar extends StatefulWidget {
  final double size;
  
  const PassengerSearchRadar({
    super.key,
    this.size = 200,
  });

  @override
  State<PassengerSearchRadar> createState() => _PassengerSearchRadarState();
}

class _PassengerSearchRadarState extends State<PassengerSearchRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: RadarPainter(_controller.value),
          );
        },
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double progress;

  RadarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Dibujar círculos concéntricos
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Círculo exterior
    paint.color = Colors.blue.withValues(alpha: 0.3);
    canvas.drawCircle(center, radius, paint);

    // Círculo medio
    paint.color = Colors.blue.withValues(alpha: 0.2);
    canvas.drawCircle(center, radius * 0.66, paint);

    // Círculo interior
    paint.color = Colors.blue.withValues(alpha: 0.1);
    canvas.drawCircle(center, radius * 0.33, paint);

    // Dibujar líneas radiales
    paint.color = Colors.blue.withValues(alpha: 0.1);
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      canvas.drawLine(
        center,
        Offset(endX, endY),
        paint,
      );
    }

    // Dibujar barrido del radar
    final sweepAngle = progress * math.pi * 2;
    final sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          Colors.blue.withValues(alpha: 0.0),
          Colors.blue.withValues(alpha: 0.3),
          Colors.blue.withValues(alpha: 0.6),
          Colors.blue.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        startAngle: sweepAngle - 0.3,
        endAngle: sweepAngle + 0.3,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle - 0.3,
      0.6,
      true,
      sweepPaint,
    );

    // Punto central
    final centerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}













