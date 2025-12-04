// lib/screens/splash/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../screens/auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _imageLoaded = false;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    // Ocultar barra de estado y navegación para pantalla completa (solo en móvil)
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    
    // Precargar la imagen antes de mostrarla
    _preloadImage();
    
    // Esperar 3 segundos y luego navegar
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Restaurar barra de estado (solo en móvil)
        if (!kIsWeb) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
        );
      }
    });
  }

  Future<void> _preloadImage() async {
    try {
      // Precargar el asset para asegurar que esté disponible
      await rootBundle.load('assets/lottie/logo/iconoRideUPT.png');
      if (mounted) {
        setState(() {
          _imageLoaded = true;
          _imageError = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error al precargar iconoRideUPT.png: $e');
      if (mounted) {
        setState(() {
          _imageError = true;
          _imageLoaded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Restaurar barra de estado al salir (solo en móvil)
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Center(
          child: _buildSplashImage(),
        ),
      ),
    );
  }

  Widget _buildSplashImage() {
    // Si hay error, mostrar placeholder
    if (_imageError) {
      return _buildPlaceholder();
    }

    // Si la imagen aún no se ha cargado, mostrar indicador de carga
    if (!_imageLoaded) {
      return const SizedBox(
        width: 300,
        height: 300,
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
          ),
        ),
      );
    }

    // Usar Image.asset directamente para mejor compatibilidad con web y móvil
    return Image.asset(
      'assets/lottie/logo/iconoRideUPT.png',
      fit: BoxFit.contain,
      width: 300,
      height: 300,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        // Si hay error cargando la imagen, mostrar un placeholder
        debugPrint('❌ Error cargando iconoRideUPT.png: $error');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('Ruta intentada: assets/lottie/logo/iconoRideUPT.png');
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 300,
      height: 300,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.directions_car,
                size: 80,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'RideUPT',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Conecta tu camino',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

