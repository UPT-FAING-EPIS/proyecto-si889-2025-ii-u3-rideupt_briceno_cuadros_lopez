// lib/widgets/lottie_loading.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final String? message;
  final Color? messageColor;
  final double? messageFontSize;

  const LottieLoading({
    super.key,
    this.width,
    this.height,
    this.message,
    this.messageColor,
    this.messageFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/Loading.json',
            width: width ?? (isTablet ? 200 : 150),
            height: height ?? (isTablet ? 200 : 150),
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
          ),
          if (message != null) ...[
            SizedBox(height: isTablet ? 24 : 16),
            Text(
              message!,
              style: TextStyle(
                color: messageColor ?? colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: messageFontSize ?? (isTablet ? 18 : 16),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// Widget específico para pantallas completas
class LottieLoadingScreen extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LottieLoadingScreen({
    super.key,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      body: LottieLoading(
        message: message,
        messageColor: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

// Widget para botones de carga
class LottieLoadingButton extends StatelessWidget {
  final String? message;
  final double? size;

  const LottieLoadingButton({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset(
          'assets/lottie/Loading.json',
          width: this.size ?? (isTablet ? 60 : 40),
          height: this.size ?? (isTablet ? 60 : 40),
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
        ),
        if (message != null) ...[
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            message!,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}



