// lib/utils/app_config.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // =======================================================================
  // --- ¡SELECTOR DE ENTORNO! ---
  // Cambia este valor a 'true' para apuntar al servidor Debian.
  // Cambia este valor a 'false' para apuntar a tu entorno local (localhost/Docker).
  // =======================================================================
  static const bool _useServer = true;

  // --- CONFIGURACIÓN PARA EL SERVIDOR DE DESARROLLO (DEBIAN) ---
  // Dominio: rideupt.sytes.net
  // IP: 161.132.50.113
  static const String _serverIp = "rideupt.sytes.net";  // Dominio No-IP configurado
  static const String _serverPort = "443";  // Puerto HTTPS (443)
  static const bool _useHttps = true;  // HTTPS activado

  // --- CONFIGURACIÓN PARA EL ENTORNO LOCAL (TU PC) ---
  static String get _localHost {
    // En web, siempre usar localhost
    if (kIsWeb) {
      return 'localhost';
    }
    
    if (Platform.isAndroid) {
      // IP especial para que el emulador de Android se conecte al localhost de tu PC.
      return '10.0.2.2';
    } else {
      // Para el simulador de iOS y otras plataformas, 'localhost' funciona.
      return 'localhost';
    }
  }
  static const String _localPort = "3000";


  // --- GETTERS PÚBLICOS QUE LA APP USARÁ ---
  // Estos getters deciden qué configuración usar basándose en la variable _useServer.

  /// Devuelve la URL base para las peticiones de la API REST.
  /// Ejemplo: https://TU_IP:443/api o http://localhost:3000/api
  static String get baseUrl {
    final host = _useServer ? _serverIp : _localHost;
    final port = _useServer ? _serverPort : _localPort;
    
    // IMPORTANTE: Para móvil, usar HTTP directamente al puerto 3000
    // hasta que Apache/Nginx esté configurado correctamente
    // Para web, usar HTTPS si está configurado
    if (_useServer && _useHttps && kIsWeb) {
      // Si el puerto es 443, no incluirlo (puerto por defecto HTTPS)
      if (port == '443') {
        return 'https://$host/api';
      }
      return 'https://$host:$port/api';
    }
    
    // Para móvil o sin HTTPS, usar HTTP directamente al puerto 3000
    // Esto evita problemas con Apache que está interceptando
    if (_useServer && !kIsWeb) {
      return 'http://$host:3000/api';
    }
    
    // En desarrollo local, usar HTTP
    return 'http://$host:$port/api';
  }

  /// Devuelve la URL base para la conexión de Socket.IO.
  /// Ejemplo: https://TU_IP:443 o http://localhost:3000
  static String get socketUrl {
    final host = _useServer ? _serverIp : _localHost;
    final port = _useServer ? _serverPort : _localPort;
    
    // IMPORTANTE: Para móvil, usar HTTP directamente al puerto 3000
    // hasta que Apache/Nginx esté configurado correctamente
    // Para web, usar HTTPS si está configurado
    if (_useServer && _useHttps && kIsWeb) {
      // Si el puerto es 443, no incluirlo (puerto por defecto HTTPS)
      if (port == '443') {
        return 'https://$host';
      }
      return 'https://$host:$port';
    }
    
    // Para móvil o sin HTTPS, usar HTTP directamente al puerto 3000
    // Esto evita problemas con Apache que está interceptando
    if (_useServer && !kIsWeb) {
      return 'http://$host:3000';
    }
    
    // En desarrollo local, usar HTTP
    return 'http://$host:$port';
  }
}