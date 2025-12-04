// lib/utils/image_utils.dart
import 'app_config.dart';

class ImageUtils {
  /// Construye la URL completa de una imagen
  /// Si la URL ya es absoluta (http/https), la devuelve tal cual
  /// Si es relativa, la construye usando la URL base del servidor
  static String buildImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // Si ya es una URL absoluta, devolverla tal cual
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Construir URL completa
    final baseUrl = AppConfig.socketUrl;
    
    // Limpiar la URL relativa
    String cleanUrl = imageUrl;
    if (cleanUrl.startsWith('/')) {
      cleanUrl = cleanUrl.substring(1);
    }
    
    // Construir URL completa
    final fullUrl = baseUrl.endsWith('/') 
        ? '$baseUrl$cleanUrl' 
        : '$baseUrl/$cleanUrl';
    
    return fullUrl;
  }

  /// Verifica si una URL de imagen es válida
  static bool isValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return false;
    }
    
    if (imageUrl == 'default_avatar.png') {
      return false;
    }
    
    // Verificar que sea una URL válida
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) {
      return false;
    }
    
    // Si no tiene esquema, asumir que es relativa y construirla
    if (!uri.hasScheme) {
      return true; // Es relativa, se construirá
    }
    
    // Si tiene esquema, verificar que sea http o https
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  /// Obtiene la URL de imagen lista para usar
  static String? getImageUrl(String? imageUrl) {
    if (!isValidImageUrl(imageUrl)) {
      return null;
    }
    
    return buildImageUrl(imageUrl);
  }
}

