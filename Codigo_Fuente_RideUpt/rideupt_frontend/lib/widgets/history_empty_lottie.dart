// lib/widgets/history_empty_lottie.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class HistoryEmptyLottie extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final double? width;
  final double? height;
  final Color? messageColor;
  final Color? subtitleColor;
  final double? messageFontSize;
  final double? subtitleFontSize;
  final bool isDriver;

  const HistoryEmptyLottie({
    super.key,
    this.message,
    this.subtitle,
    this.width,
    this.height,
    this.messageColor,
    this.subtitleColor,
    this.messageFontSize,
    this.subtitleFontSize,
    this.isDriver = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // Mensajes por defecto según el tipo de usuario
    final defaultMessage = message ?? 
      (isDriver ? 'No has creado viajes' : 'No tienes viajes reservados');
    
    final defaultSubtitle = subtitle ?? 
      (isDriver 
        ? 'Crea tu primer viaje para comenzar a conectar con estudiantes'
        : 'Busca y reserva un viaje disponible');

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 48 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación Lottie
            Lottie.asset(
              'assets/lottie/Historial.json',
              width: width ?? (isTablet ? 250 : 200),
              height: height ?? (isTablet ? 250 : 200),
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
            
            SizedBox(height: isTablet ? 32 : 24),
            
            // Mensaje principal
            Text(
              defaultMessage,
              style: TextStyle(
                color: messageColor ?? colorScheme.onSurface,
                fontSize: messageFontSize ?? (isTablet ? 24 : 20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isTablet ? 16 : 12),
            
            // Subtítulo
            Text(
              defaultSubtitle,
              style: TextStyle(
                color: subtitleColor ?? colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: subtitleFontSize ?? (isTablet ? 18 : 16),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget específico para pantallas completas de historial vacío
class HistoryEmptyScreen extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final Color? backgroundColor;
  final bool isDriver;

  const HistoryEmptyScreen({
    super.key,
    this.message,
    this.subtitle,
    this.backgroundColor,
    this.isDriver = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      body: HistoryEmptyLottie(
        message: message,
        subtitle: subtitle,
        isDriver: isDriver,
      ),
    );
  }
}



