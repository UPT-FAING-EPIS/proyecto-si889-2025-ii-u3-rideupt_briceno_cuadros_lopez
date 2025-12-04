import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/safe_area_wrapper.dart';
import '../../services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _termsAccepted = false;
  bool _isLoading = false;

  List<OnboardingPage> get _pages => [
    OnboardingPage(
      type: OnboardingPageType.welcome,
      title: '¡Bienvenido a RideUpt!',
      description: 'La plataforma que conecta estudiantes para compartir viajes seguros y económicos.',
      color: Theme.of(context).colorScheme.primary,
    ),
    OnboardingPage(
      type: OnboardingPageType.location,
      title: 'Necesitamos tu ubicación',
      description: 'Para mostrarte viajes cercanos y crear rutas precisas, necesitamos acceso a tu ubicación.',
      color: Theme.of(context).colorScheme.secondary,
    ),
    OnboardingPage(
      type: OnboardingPageType.notification,
      title: 'Necesitamos notificarte',
      description: 'Te mantendremos informado sobre tus viajes, solicitudes y actualizaciones importantes.',
      color: Theme.of(context).colorScheme.tertiary,
    ),
    OnboardingPage(
      type: OnboardingPageType.terms,
      title: 'Términos y Condiciones',
      description: 'Por favor, lee y acepta nuestros términos y condiciones para continuar.',
      color: Theme.of(context).colorScheme.primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_currentPage == 0) {
      // Pantalla de bienvenida - solo avanzar
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == 1) {
      // Pantalla de ubicación - solicitar permiso
      await _requestLocationPermission();
    } else if (_currentPage == 2) {
      // Pantalla de notificaciones - solicitar permiso
      await _requestNotificationPermission();
    } else if (_currentPage == 3) {
      // Pantalla de términos - completar onboarding
      if (_termsAccepted) {
        await _completeOnboarding();
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);

    try {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showPermissionDialog(
          'Servicios de ubicación deshabilitados',
          'Por favor, habilita los servicios de ubicación en la configuración de tu dispositivo.',
        );
        setState(() => _isLoading = false);
        return;
      }

      // Solicitar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDialog(
            'Permiso de ubicación denegado',
            'RideUpt necesita acceso a tu ubicación para funcionar correctamente. Puedes habilitarlo en la configuración.',
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog(
          'Permiso de ubicación permanentemente denegado',
          'Por favor, habilita el permiso de ubicación en la configuración de la aplicación.',
        );
        setState(() => _isLoading = false);
        return;
      }

      // Si llegamos aquí, los permisos están otorgados
      setState(() {
        _isLoading = false;
      });

      // Avanzar a la siguiente pantalla
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      _showPermissionDialog(
        'Error al solicitar permisos',
        'Ocurrió un error al solicitar los permisos. Inténtalo de nuevo.',
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    try {
      await NotificationService().requestPermissions();
      
      setState(() {
        _isLoading = false;
      });

      // Avanzar a la siguiente pantalla
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      _showPermissionDialog(
        'Error al solicitar permisos',
        'Ocurrió un error al solicitar los permisos de notificaciones. Inténtalo de nuevo.',
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  void _showPermissionDialog(String title, String message) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(fontSize: isSmallScreen ? 18.0 : null),
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: TextStyle(fontSize: isSmallScreen ? 14.0 : null),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendido',
              style: TextStyle(fontSize: isSmallScreen ? 14.0 : null),
            ),
          ),
          if (title.contains('permanentemente') || title.contains('deshabilitados'))
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Abrir configuración del sistema
                Geolocator.openAppSettings();
              },
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12.0 : 16.0,
                  vertical: isSmallScreen ? 8.0 : 12.0,
                ),
              ),
              child: Text(
                'Configuración',
                style: TextStyle(fontSize: isSmallScreen ? 14.0 : null),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final isSmallScreen = size.height < 700;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _pages[_currentPage].color.withValues(alpha: 0.1),
              _pages[_currentPage].color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeAreaWrapper(
          child: Column(
            children: [
              // Skip button (solo en las primeras 3 pantallas)
              if (_currentPage < _pages.length - 1)
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 8.0 : (isTablet ? 24.0 : 16.0)),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () => _pageController.animateToPage(
                        _pages.length - 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8.0 : 16.0,
                          vertical: isSmallScreen ? 4.0 : 8.0,
                        ),
                      ),
                      child: Text(
                        'Omitir',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14.0 : null,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              
              // Page indicators
              Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8.0 : 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _pages[_currentPage].color
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Terms and conditions (only on last page)
              if (_currentPage == _pages.length - 1) ...[
                ResponsivePadding(
                  mobile: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 24.0,
                    vertical: isSmallScreen ? 8.0 : 0.0,
                  ),
                  tablet: const EdgeInsets.symmetric(horizontal: 40),
                  desktop: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: isSmallScreen ? 2.0 : 4.0),
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() => _termsAccepted = value ?? false);
                          },
                          materialTapTargetSize: isSmallScreen 
                              ? MaterialTapTargetSize.shrinkWrap 
                              : MaterialTapTargetSize.padded,
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _termsAccepted = !_termsAccepted);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: isSmallScreen ? 12.0 : (isTablet ? 16 : 14),
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'Acepto los '),
                                TextSpan(
                                  text: 'Términos y Condiciones',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context).pushNamed('/terms'),
                                ),
                                const TextSpan(text: ' y la '),
                                TextSpan(
                                  text: 'Política de Privacidad',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context).pushNamed('/privacy'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8.0 : (isTablet ? 32 : 24)),
              ] else
                SizedBox(height: isSmallScreen ? 8.0 : 16.0),
              
              // Navigation buttons
              SafeAreaWrapper(
                top: false,
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : (isTablet ? 32.0 : 24.0)),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12.0 : (isTablet ? 16 : 14),
                              ),
                            ),
                            child: Text(
                              'Anterior',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13.0 : (isTablet ? 16 : 14),
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) SizedBox(width: isSmallScreen ? 12.0 : (isTablet ? 20 : 16)),
                      Expanded(
                        flex: _currentPage > 0 ? 1 : 1,
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : FilledButton(
                                onPressed: _currentPage == _pages.length - 1
                                    ? (_termsAccepted ? _handleNext : null)
                                    : _handleNext,
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 12.0 : (isTablet ? 16 : 14),
                                  ),
                                ),
                                child: Text(
                                  _currentPage == _pages.length - 1 ? 'Comenzar' : 'Siguiente',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13.0 : (isTablet ? 16 : 14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final isSmallScreen = size.height < 700;
    
    // Calcular tamaños adaptativos basados en el tamaño de pantalla
    final screenHeight = size.height;
    final animationSize = isSmallScreen 
        ? (screenHeight * 0.25).clamp(150.0, 200.0)
        : (isTablet ? 300.0 : 250.0);
    final iconSize = isSmallScreen ? 60.0 : (isTablet ? 100.0 : 80.0);
    final iconPadding = isSmallScreen ? 24.0 : (isTablet ? 48.0 : 32.0);
    final titleFontSize = isSmallScreen 
        ? 22.0 
        : (isTablet ? 32.0 : 28.0);
    final descriptionFontSize = isSmallScreen ? 14.0 : (isTablet ? 18.0 : 16.0);
    final spacing1 = isSmallScreen ? 24.0 : (isTablet ? 64.0 : 48.0);
    final spacing2 = isSmallScreen ? 12.0 : (isTablet ? 24.0 : 16.0);
    
    return ResponsivePadding(
      mobile: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      tablet: const EdgeInsets.all(40.0),
      desktop: const EdgeInsets.all(60.0),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: size.height - (isSmallScreen ? 200 : 300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animation para bienvenida, iconos para otras pantallas
              if (page.type == OnboardingPageType.welcome)
                SizedBox(
                  width: animationSize,
                  height: animationSize,
                  child: Lottie.asset(
                    'assets/lottie/Loading.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: page.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: page.color.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    page.type == OnboardingPageType.location
                        ? Icons.location_on
                        : page.type == OnboardingPageType.notification
                            ? Icons.notifications
                            : Icons.description,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
              SizedBox(height: spacing1),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: page.color,
                  fontSize: titleFontSize,
                ),
              ),
              SizedBox(height: spacing2),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                  fontSize: descriptionFontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum OnboardingPageType {
  welcome,
  location,
  notification,
  terms,
}

class OnboardingPage {
  final OnboardingPageType type;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.type,
    required this.title,
    required this.description,
    required this.color,
  });
}
