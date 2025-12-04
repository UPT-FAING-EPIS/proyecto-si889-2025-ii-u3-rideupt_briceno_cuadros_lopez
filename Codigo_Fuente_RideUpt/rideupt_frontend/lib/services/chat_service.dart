// lib/services/chat_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:rideupt_app/utils/app_config.dart';
import 'package:rideupt_app/providers/auth_provider.dart';

class ChatMessage {
  final String id;
  final String tripId;
  final String userId;
  final String userName;
  final String userPhoto;
  final String message;
  final DateTime timestamp;
  final bool isDriver;

  ChatMessage({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.message,
    required this.timestamp,
    required this.isDriver,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhoto: json['userPhoto'] as String? ?? 'default_avatar.png',
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isDriver: json['isDriver'] as bool? ?? false,
    );
  }
}

class ChatService {
  static ChatService? _instance;
  io.Socket? _socket;
  String? _currentTripId;
  String? _token;

  // Streams para los mensajes
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? get currentTripId => _currentTripId;

  ChatService._();

  factory ChatService.getInstance([AuthProvider? authProvider]) {
    _instance ??= ChatService._();
    return _instance!;
  }

  /// Conectar al servidor de sockets
  void connect(String token) {
    if (_socket?.connected ?? false) {
      return;
    }

    _token = token;

    try {
      _socket = io.io(
        AppConfig.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setAuth({'token': token})
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('✅ ChatService: Conectado al servidor de sockets');
        _connectionController.add(true);
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ ChatService: Desconectado del servidor de sockets');
        _connectionController.add(false);
      });

      _socket!.onConnectError((error) {
        debugPrint('❌ ChatService: Error de conexión: $error');
        _connectionController.add(false);
      });

      _socket!.onError((error) {
        debugPrint('❌ ChatService: Error: $error');
      });

      // Escuchar nuevos mensajes
      _socket!.on('newChatMessage', (data) {
        try {
          if (data is Map<String, dynamic>) {
            final message = ChatMessage.fromJson(data);
            _messageController.add(message);
          }
        } catch (e) {
          debugPrint('Error al procesar mensaje: $e');
        }
      });

      // Confirmación de mensaje enviado
      _socket!.on('chatMessageSent', (data) {
        try {
          if (data is Map<String, dynamic>) {
            final message = ChatMessage.fromJson(data);
            _messageController.add(message);
          }
        } catch (e) {
          debugPrint('Error al procesar confirmación de mensaje: $e');
        }
      });

      // Recibir historial de mensajes al unirse
      _socket!.on('chatHistory', (data) {
        try {
          if (data is List) {
            for (var item in data) {
              if (item is Map<String, dynamic>) {
                final message = ChatMessage.fromJson(item);
                _messageController.add(message);
              }
            }
            debugPrint('📜 Historial de mensajes recibido: ${data.length} mensajes');
          }
        } catch (e) {
          debugPrint('Error al procesar historial: $e');
        }
      });

      // Notificación de que el chat fue cerrado
      _socket!.on('tripChatClosed', (data) {
        try {
          if (data is Map<String, dynamic>) {
            final tripId = data['tripId'] as String?;
            final reason = data['reason'] as String?;
            debugPrint('🔒 Chat del viaje $tripId cerrado. Razón: $reason');
            // El frontend puede manejar esto según sea necesario
          }
        } catch (e) {
          debugPrint('Error al procesar cierre de chat: $e');
        }
      });

      // Notificación de que un pasajero abandonó el chat
      _socket!.on('passengerLeftChat', (data) {
        try {
          if (data is Map<String, dynamic>) {
            final passengerName = data['passengerName'] as String?;
            debugPrint('👋 Pasajero $passengerName abandonó el chat');
            // El frontend puede mostrar una notificación si es necesario
          }
        } catch (e) {
          debugPrint('Error al procesar abandono de pasajero: $e');
        }
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('Error al conectar ChatService: $e');
      _connectionController.add(false);
    }
  }

  /// Desconectar del servidor (solo se debe llamar al cerrar sesión)
  void disconnect() {
    if (_currentTripId != null) {
      leaveTripChat(_currentTripId!);
      _currentTripId = null;
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionController.add(false);
  }

  /// Salir del chat actual sin desconectar el socket
  void leaveCurrentChat() {
    if (_currentTripId != null) {
      leaveTripChat(_currentTripId!);
      _currentTripId = null;
    }
  }

  /// Unirse al chat de un viaje
  Future<bool> joinTripChat(String tripId) async {
    if (_socket == null || !_socket!.connected) {
      if (_token != null) {
        connect(_token!);
        // Esperar un poco para que se conecte
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        return false;
      }
    }

    if (_socket == null || !_socket!.connected) {
      return false;
    }

    try {
      final completer = Completer<bool>();
      bool responseReceived = false;

      // Escuchar respuesta una sola vez
      void responseHandler(dynamic response) {
        if (responseReceived) return;
        responseReceived = true;
        _socket!.off('joinTripChatResponse');
        
        if (response is Map<String, dynamic>) {
          final success = response['success'] as bool? ?? false;
          if (success) {
            _currentTripId = tripId;
            // El historial se recibirá automáticamente a través del evento 'chatHistory'
            completer.complete(true);
          } else {
            debugPrint('Error al unirse al chat: ${response['message']}');
            completer.complete(false);
          }
        } else {
          completer.complete(false);
        }
      }

      _socket!.once('joinTripChatResponse', responseHandler);
      _socket!.emit('joinTripChat', tripId);

      // Timeout después de 5 segundos
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (!responseReceived) {
            responseReceived = true;
            _socket?.off('joinTripChatResponse');
          }
          debugPrint('Timeout al unirse al chat');
          return false;
        },
      );
    } catch (e) {
      debugPrint('Error al unirse al chat: $e');
      return false;
    }
  }

  /// Salir del chat de un viaje
  void leaveTripChat(String tripId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leaveTripChat', tripId);
      if (_currentTripId == tripId) {
        _currentTripId = null;
      }
    }
  }

  /// Enviar un mensaje de chat
  Future<bool> sendMessage(String tripId, String message) async {
    if (_socket == null || !_socket!.connected) {
      return false;
    }

    if (message.trim().isEmpty) {
      return false;
    }

    try {
      final completer = Completer<bool>();
      bool responseReceived = false;
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();

      // Escuchar respuesta una sola vez
      void responseHandler(dynamic response) {
        if (responseReceived) return;
        responseReceived = true;
        _socket!.off('sendChatMessageResponse');
        
        if (response is Map<String, dynamic>) {
          final success = response['success'] as bool? ?? false;
          completer.complete(success);
        } else {
          completer.complete(false);
        }
      }

      _socket!.once('sendChatMessageResponse', responseHandler);
      _socket!.emit('sendChatMessage', {
        'tripId': tripId,
        'message': message.trim(),
        'messageId': messageId,
      });

      // Timeout después de 5 segundos
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (!responseReceived) {
            responseReceived = true;
            _socket?.off('sendChatMessageResponse');
          }
          debugPrint('Timeout al enviar mensaje');
          return false;
        },
      );
    } catch (e) {
      debugPrint('Error al enviar mensaje: $e');
      return false;
    }
  }

  /// Limpiar recursos
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}

