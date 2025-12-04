// lib/widgets/gps_searching_lottie.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GpsSearchingLottie extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final Color? messageColor;
  final double? messageFontSize;
  final double? width;
  final double? height;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const GpsSearchingLottie({
    super.key,
    this.message,
    this.subtitle,
    this.messageColor,
    this.messageFontSize,
    this.width,
    this.height,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/Buscando.json',
              width: width ?? (isTablet ? 300 : 250),
              height: height ?? (isTablet ? 300 : 250),
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            if (message != null) ...[
              Text(
                message!,
                style: TextStyle(
                  color: messageColor ?? colorScheme.onSurface,
                  fontSize: messageFontSize ?? (isTablet ? 24 : 20),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 16 : 12),
            ],
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: TextStyle(
                  color: messageColor?.withValues(alpha: 0.7) ?? colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: (messageFontSize ?? (isTablet ? 18 : 16)) - 2,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 24 : 20),
            ],
            if (onRetry != null) ...[
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryButtonText ?? 'Buscar de nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 24,
                    vertical: isTablet ? 16 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget específico para cuando no hay viajes disponibles (pasajeros)
class NoTripsAvailableLottie extends StatelessWidget {
  final VoidCallback? onRefresh;

  const NoTripsAvailableLottie({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GpsSearchingLottie(
      message: 'No hay viajes disponibles',
      subtitle: 'No se encontraron viajes en este momento.\nIntenta más tarde o crea un viaje como conductor.',
      onRetry: onRefresh,
      retryButtonText: 'Buscar viajes',
    );
  }
}

// Widget específico para cuando el conductor no ha publicado viajes
class NoDriverTripsLottie extends StatelessWidget {
  final VoidCallback? onCreateTrip;

  const NoDriverTripsLottie({
    super.key,
    this.onCreateTrip,
  });

  @override
  Widget build(BuildContext context) {
    return GpsSearchingLottie(
      message: 'No tienes viajes activos',
      subtitle: 'Publica un viaje para comenzar a compartir con otros estudiantes.',
      onRetry: onCreateTrip,
      retryButtonText: 'Crear viaje',
    );
  }
}

// Widget específico para búsqueda en progreso
class SearchingTripsLottie extends StatelessWidget {
  final String? customMessage;

  const SearchingTripsLottie({
    super.key,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GpsSearchingLottie(
      message: customMessage ?? 'Buscando viajes...',
      subtitle: 'Estamos buscando los mejores viajes para ti',
      width: 200,
      height: 200,
    );
  }
}



