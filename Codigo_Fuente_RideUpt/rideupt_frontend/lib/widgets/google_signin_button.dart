// lib/widgets/google_signin_button.dart
import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleSignInButton extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSuccess;
  final Function(String)? onError;
  final String? customText;
  final bool isCompact;
  final GoogleSignInStyle style;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.customText,
    this.isCompact = false,
    this.style = GoogleSignInStyle.standard,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    // Animación de press
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _googleAuthService.signInWithGoogle();

      if (result == null) {
        // Usuario canceló
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Guardar el token en storage seguro
      if (result['token'] != null) {
        await _storage.write(key: 'token', value: result['token']);
        await _storage.write(key: 'userId', value: result['_id']);
        await _storage.write(key: 'userRole', value: result['role']);
      }

      // Feedback haptic (si está disponible)
      // HapticFeedback.lightImpact();

      if (widget.onSuccess != null && mounted) {
        widget.onSuccess!(result);
      }
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Cerrar sesión de Google si hay error
      try {
        await _googleAuthService.signOut();
      } catch (signOutError) {
        debugPrint('Error al cerrar sesión: $signOutError');
      }

      if (widget.onError != null && mounted) {
        widget.onError!(errorMessage);
      } else {
        if (mounted) {
          _showErrorSnackBar(errorMessage);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.style) {
      case GoogleSignInStyle.outlined:
        return _buildOutlinedButton(theme);
      case GoogleSignInStyle.filled:
        return _buildFilledButton(theme);
      case GoogleSignInStyle.icon:
        return _buildIconButton(theme);
      case GoogleSignInStyle.standard:
      return _buildStandardButton(theme);
    }
  }

  Widget _buildStandardButton(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: widget.isCompact ? 40 : 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFDADCE0), // Color oficial de Google
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _handleGoogleSignIn,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _isLoading
                    ? _buildLoadingIndicator()
                    : _buildButtonContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: widget.isCompact ? 48 : 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.outline,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _isLoading ? _buildLoadingIndicator() : _buildButtonContent(),
      ),
    );
  }

  Widget _buildFilledButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: widget.isCompact ? 48 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isLoading
                ? _buildLoadingIndicator(isLight: true)
                : _buildButtonContent(isLight: true),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(ThemeData theme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleGoogleSignIn,
          customBorder: const CircleBorder(),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : _buildGoogleLogo(32),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent({bool isLight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGoogleLogo(20),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            widget.customText ?? 'Continuar con Google',
            style: TextStyle(
              fontSize: widget.isCompact ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: isLight ? Colors.white : const Color(0xFF3C4043), // Color oficial de Google
              letterSpacing: 0.25,
              fontFamily: 'Roboto', // Fuente oficial de Google
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator({bool isLight = false}) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLight ? Colors.white : const Color(0xFF3C4043),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Conectando...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isLight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF5F6368),
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleLogo(double size) {
    // Logo oficial de Google - versión simplificada pero reconocible
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GoogleLogoPainter(),
      ),
    );
  }
}

/// Painter para el logo oficial de Google
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Logo de Google: círculo dividido en 4 secciones de colores
    // Con un círculo blanco central que crea el efecto característico
    
    // Sección azul (arriba-izquierda, -90° a 0°)
    paint.color = const Color(0xFF4285F4); // Google Blue
    canvas.drawArc(rect, -1.5708, 1.5708, true, paint);

    // Sección roja (arriba-derecha, 0° a 90°)
    paint.color = const Color(0xFFEA4335); // Google Red
    canvas.drawArc(rect, 0, 1.5708, true, paint);

    // Sección amarilla (abajo-derecha, 90° a 180°)
    paint.color = const Color(0xFFFBBC05); // Google Yellow
    canvas.drawArc(rect, 1.5708, 1.5708, true, paint);

    // Sección verde (abajo-izquierda, 180° a 270°)
    paint.color = const Color(0xFF34A853); // Google Green
    canvas.drawArc(rect, 3.14159, 1.5708, true, paint);

    // Círculo blanco central que crea el efecto del logo de Google
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Estilos disponibles para el botón de Google Sign-In
enum GoogleSignInStyle {
  /// Botón estándar blanco con borde (recomendado por Google)
  standard,

  /// Botón con borde pero sin relleno
  outlined,

  /// Botón con gradiente de color
  filled,

  /// Solo ícono circular (ideal para espacios reducidos)
  icon,
}



