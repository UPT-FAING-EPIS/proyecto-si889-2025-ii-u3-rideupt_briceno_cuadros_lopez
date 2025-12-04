import 'package:flutter/material.dart';

/// ============================================================================
/// RIDEUPT DESIGN SYSTEM - Sistema de Diseño Visual Profesional
/// ============================================================================
/// 
/// Sistema de diseño completo inspirado en inDrive, Uber y Bolt.
/// Transmite: Seguridad, Eficiencia, Confianza y Modernidad
///
/// PALETA DE COLORES PROFESIONAL:
/// - Primario: Azul Petróleo/Verde Azulado (#1E88E5 / #0288D1) - Confianza y Tecnología
/// - Secundario: Azul Profundo (#1565C0) - Profesionalismo
/// - Acentos: Verde Azulado (#00ACC1) - Movilidad y Eficiencia
/// - Neutros: Grises sofisticados para fondos y superficies
///
/// ============================================================================

class AppTheme {
  // ============================================================================
  // DESIGN TOKENS - Tokens de Diseño del Sistema
  // ============================================================================
  
  // --- COLORES PRIMARIOS ---
  /// Color primario: Azul Petróleo/Verde Azulado
  /// Transmite: Confianza, Tecnología, Movilidad, Profesionalismo
  static const Color _primaryColor = Color(0xFF1E88E5); // Azul Petróleo vibrante
  
  /// Color secundario: Azul Profundo
  /// Transmite: Estabilidad, Confianza, Profesionalismo
  static const Color _secondaryColor = Color(0xFF1565C0); // Azul Profundo
  
  /// Color terciario: Verde Azulado (Cyan)
  /// Transmite: Movilidad, Eficiencia, Modernidad
  static const Color _tertiaryColor = Color(0xFF00ACC1); // Verde Azulado
  
  // ============================================================================
  // ESPACIADOS Y DIMENSIONES
  // ============================================================================
  
  /// Sistema de espaciado basado en 8px (8pt grid system)
  static const double spacingXS = 4.0;   // 0.5x
  static const double spacingSM = 8.0;   // 1x
  static const double spacingMD = 16.0;  // 2x
  static const double spacingLG = 24.0;  // 3x
  static const double spacingXL = 32.0;  // 4x
  static const double spacingXXL = 48.0; // 6x
  
  /// Radios de borde elegantes
  static const double radiusSM = 8.0;   // Elementos pequeños
  static const double radiusMD = 12.0;  // Cards y botones
  static const double radiusLG = 16.0;  // Contenedores grandes
  static const double radiusXL = 24.0;  // Modales y diálogos
  static const double radiusRound = 999.0; // Botones circulares
  
  // ============================================================================
  // TEMA CLARO - Light Theme
  // ============================================================================
  /// 
  /// Percepción: Limpio, Profesional, Moderno, Confiable
  /// Ideal para: Uso diurno, espacios bien iluminados
  /// 
  static ThemeData get lightTheme {
    // Construir ColorScheme personalizado
    final colorScheme = ColorScheme.light(
      // Colores principales
      primary: _primaryColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE3F2FD), // Azul muy claro
      onPrimaryContainer: const Color(0xFF0D47A1), // Azul muy oscuro
      
      // Colores secundarios
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE1F5FE), // Cyan muy claro
      onSecondaryContainer: const Color(0xFF01579B), // Azul oscuro
      
      // Colores terciarios
      tertiary: _tertiaryColor,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE0F7FA), // Cyan claro
      onTertiaryContainer: const Color(0xFF006064), // Cyan oscuro
      
      // Fondos y superficies
      surface: Colors.white,
      onSurface: const Color(0xFF1A1A1A), // Casi negro
      surfaceContainerHighest: const Color(0xFFFAFAFA), // Gris casi blanco
      onSurfaceVariant: const Color(0xFF616161), // Gris medio
      
      // Fondos alternativos
      inverseSurface: const Color(0xFF1A1A1A),
      onInverseSurface: Colors.white,
      
      // Bordes y divisores
      outline: const Color(0xFFE0E0E0), // Gris claro
      outlineVariant: const Color(0xFFF5F5F5), // Gris muy claro
      
      // Estados semánticos
      error: const Color(0xFFE53935), // Rojo Error
      onError: Colors.white,
      errorContainer: const Color(0xFFFFEBEE), // Rojo muy claro
      onErrorContainer: const Color(0xFFB71C1C), // Rojo oscuro
      
      // Otros
      shadow: Colors.black,
      scrim: Colors.black,
      inversePrimary: _primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      
      // ========================================================================
      // TIPOGRAFÍA - Inter (moderna y legible)
      // ========================================================================
      fontFamily: 'Roboto', // Fallback a Roboto (similar a Inter)
      textTheme: _buildLightTextTheme(colorScheme),
      
      // ========================================================================
      // APP BAR
      // ========================================================================
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),
      
      // ========================================================================
      // CARDS
      // ========================================================================
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      
      // ========================================================================
      // BOTONES
      // ========================================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          minimumSize: const Size(64, 48),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          minimumSize: const Size(64, 48),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          minimumSize: const Size(64, 48),
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingSM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // ========================================================================
      // INPUTS
      // ========================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      
      // ========================================================================
      // CHIPS
      // ========================================================================
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingSM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      
      // ========================================================================
      // DIVISORES
      // ========================================================================
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
      
      // ========================================================================
      // BOTTOM NAVIGATION BAR
      // ========================================================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // ========================================================================
      // FLOATING ACTION BUTTON
      // ========================================================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      
      // ========================================================================
      // DIÁLOGOS
      // ========================================================================
      dialogTheme: DialogTheme(
        elevation: 8,
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      
      // ========================================================================
      // SNACKBARS
      // ========================================================================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),
      
      // ========================================================================
      // LIST TILES
      // ========================================================================
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
    );
  }

  // ============================================================================
  // TEMA OSCURO - Dark Theme
  // ============================================================================
  /// 
  /// Percepción: Sofisticado, Moderno, Elegante, Tecnológico
  /// Ideal para: Uso nocturno, reducir fatiga visual, ahorro de batería
  /// 
  static ThemeData get darkTheme {
    // Construir ColorScheme personalizado para modo oscuro
    final colorScheme = ColorScheme.dark(
      // Colores principales
      primary: const Color(0xFF64B5F6), // Azul más claro para contraste
      onPrimary: const Color(0xFF0D47A1), // Azul oscuro
      primaryContainer: const Color(0xFF1565C0), // Azul medio
      onPrimaryContainer: const Color(0xFFE3F2FD), // Azul muy claro
      
      // Colores secundarios
      secondary: const Color(0xFF81D4FA), // Cyan claro
      onSecondary: const Color(0xFF01579B), // Azul oscuro
      secondaryContainer: const Color(0xFF0277BD), // Azul medio
      onSecondaryContainer: const Color(0xFFE1F5FE), // Cyan muy claro
      
      // Colores terciarios
      tertiary: const Color(0xFF4DD0E1), // Cyan vibrante
      onTertiary: const Color(0xFF006064), // Cyan oscuro
      tertiaryContainer: const Color(0xFF00838F), // Cyan medio
      onTertiaryContainer: const Color(0xFFE0F7FA), // Cyan claro
      
      // Fondos y superficies
      surface: const Color(0xFF121212), // Casi negro (Material Dark)
      onSurface: const Color(0xFFE0E0E0), // Gris claro
      surfaceContainerHighest: const Color(0xFF1C1C1C), // Gris oscuro
      onSurfaceVariant: const Color(0xFFB0B0B0), // Gris medio claro
      
      // Fondos alternativos
      inverseSurface: const Color(0xFFE0E0E0),
      onInverseSurface: const Color(0xFF1A1A1A),
      
      // Bordes y divisores
      outline: const Color(0xFF424242), // Gris medio oscuro
      outlineVariant: const Color(0xFF2C2C2C), // Gris oscuro
      
      // Estados semánticos
      error: const Color(0xFFEF5350), // Rojo más claro para modo oscuro
      onError: const Color(0xFFB71C1C), // Rojo oscuro
      errorContainer: const Color(0xFFC62828), // Rojo medio oscuro
      onErrorContainer: const Color(0xFFFFCDD2), // Rojo muy claro
      
      // Otros
      shadow: Colors.black,
      scrim: Colors.black,
      inversePrimary: _primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      
      // ========================================================================
      // TIPOGRAFÍA
      // ========================================================================
      fontFamily: 'Roboto',
      textTheme: _buildDarkTextTheme(colorScheme),
      
      // ========================================================================
      // APP BAR
      // ========================================================================
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),
      
      // ========================================================================
      // CARDS
      // ========================================================================
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        color: colorScheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      
      // ========================================================================
      // BOTONES
      // ========================================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          minimumSize: const Size(64, 48),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          minimumSize: const Size(64, 48),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          minimumSize: const Size(64, 48),
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingSM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // ========================================================================
      // INPUTS
      // ========================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      
      // ========================================================================
      // CHIPS
      // ========================================================================
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingSM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      
      // ========================================================================
      // DIVISORES
      // ========================================================================
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
      
      // ========================================================================
      // BOTTOM NAVIGATION BAR
      // ========================================================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // ========================================================================
      // FLOATING ACTION BUTTON
      // ========================================================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      
      // ========================================================================
      // DIÁLOGOS
      // ========================================================================
      dialogTheme: DialogTheme(
        elevation: 8,
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      
      // ========================================================================
      // SNACKBARS
      // ========================================================================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),
      
      // ========================================================================
      // LIST TILES
      // ========================================================================
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
    );
  }

  // ============================================================================
  // TIPOGRAFÍA - Light Theme
  // ============================================================================
  static TextTheme _buildLightTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display (Títulos muy grandes)
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      
      // Headline (Títulos principales)
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      
      // Title (Títulos de sección)
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      
      // Body (Texto principal)
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      
      // Label (Etiquetas y botones)
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }

  // ============================================================================
  // TIPOGRAFÍA - Dark Theme
  // ============================================================================
  static TextTheme _buildDarkTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      
      // Headline
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      
      // Title
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      
      // Body
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      
      // Label
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }

  // ============================================================================
  // UTILIDADES RESPONSIVAS
  // ============================================================================

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return const EdgeInsets.symmetric(horizontal: spacingXXL, vertical: spacingLG);
    }
    if (width >= 600) {
      return const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD);
    }
    return const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingSM);
  }

  static double getMaxContentWidth(BuildContext context) {
    return isDesktop(context) ? 1200 : double.infinity;
  }
}
