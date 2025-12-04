// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/services/chat_service.dart';
import 'package:rideupt_app/services/socket_service.dart';
import 'package:rideupt_app/screens/trips/passenger_trip_in_progress_screen.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final Trip trip;
  const ChatScreen({super.key, required this.trip});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatService _chatService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isConnected = false;
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _initializeChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _errorMessage = 'No hay sesión activa';
        _isLoading = false;
      });
      return;
    }

    _chatService = ChatService.getInstance(authProvider);
    
    // Solo conectar si no está conectado
    if (!_chatService.isConnected) {
      _chatService.connect(token);
    }

    // Escuchar cambios de conexión
    _chatService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });
    
    // Verificar estado actual de conexión
    if (mounted) {
      setState(() {
        _isConnected = _chatService.isConnected;
      });
    }

    // Escuchar mensajes (incluye historial y nuevos mensajes)
    _chatService.messageStream.listen((message) {
      if (mounted && message.tripId == widget.trip.id) {
        setState(() {
          // Evitar duplicados
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            _scrollToBottom();
          }
        });
      }
    });

    // Unirse al chat del viaje
    final success = await _chatService.joinTripChat(widget.trip.id);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success) {
          _errorMessage = 'No se pudo conectar al chat';
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || !_isConnected) return;

    _messageController.clear();
    final success = await _chatService.sendMessage(widget.trip.id, message);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar mensaje. Intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupTripStatusListener();
  }

  void _setupTripStatusListener() {
    final socket = SocketService().socket;
    if (socket == null) return;
    
    // Escuchar cuando el conductor inicia el viaje
    socket.on('tripStarted', (data) async {
      if (!mounted) return;
      
      try {
        final tripProvider = Provider.of<TripProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.id;
        
        if (currentUserId == null) return;
        
        // Actualizar el viaje
        await tripProvider.fetchMyTrips(force: true);
        final updatedTrip = await tripProvider.fetchTripById(widget.trip.id);
        
        if (mounted && updatedTrip != null && updatedTrip.isInProgress) {
          // Buscar el estado del pasajero actual
          final myPassenger = updatedTrip.passengers.firstWhere(
            (p) => p.user.id == currentUserId,
            orElse: () => TripPassenger(
              user: authProvider.user!,
              status: 'none',
              bookedAt: DateTime.now(),
            ),
          );
          
          // Solo mostrar diálogo si el pasajero está confirmado y NO ha confirmado que está en el vehículo
          if (myPassenger.status == 'confirmed' && !myPassenger.inVehicle) {
            _showConfirmInVehicleDialog(updatedTrip, tripProvider);
          }
        }
      } catch (e) {
        debugPrint('Error al procesar inicio de viaje en chat: $e');
      }
    });
    
    // Escuchar actualizaciones del viaje
    socket.on('tripUpdated', (data) async {
      if (!mounted) return;
      
      try {
        final tripProvider = Provider.of<TripProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.id;
        
        if (currentUserId == null) return;
        
        // Actualizar el viaje
        await tripProvider.fetchMyTrips(force: true);
        final updatedTrip = await tripProvider.fetchTripById(widget.trip.id);
        
        if (mounted && updatedTrip != null) {
          // Si el viaje inició y el pasajero está confirmado Y ya confirmó que está en el vehículo, navegar
          if (updatedTrip.isInProgress) {
            final myPassenger = updatedTrip.passengers.firstWhere(
              (p) => p.user.id == currentUserId,
              orElse: () => TripPassenger(
                user: authProvider.user!,
                status: 'none',
                bookedAt: DateTime.now(),
              ),
            );
            
            // Solo redirigir si está confirmado Y ya confirmó que está en el vehículo
            if (myPassenger.status == 'confirmed' && myPassenger.inVehicle) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PassengerTripInProgressScreen(trip: updatedTrip),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error al procesar actualización de viaje en chat: $e');
      }
    });
  }

  void _showConfirmInVehicleDialog(Trip trip, TripProvider tripProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.directions_car, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Viaje Iniciado!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El conductor ha iniciado el viaje.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Ya estás en el vehículo?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('AÚN NO'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              // Confirmar que está en el vehículo
              final success = await tripProvider.confirmInVehicle(trip.id);
              
              if (mounted) {
                if (success) {
                  // Actualizar el viaje y redirigir
                  final updatedTrip = await tripProvider.fetchTripById(trip.id);
                  if (updatedTrip != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PassengerTripInProgressScreen(trip: updatedTrip),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${tripProvider.errorMessage}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('SÍ, ESTOY EN EL VEHÍCULO'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Limpiar listeners de socket
    final socket = SocketService().socket;
    socket?.off('tripUpdated');
    socket?.off('tripStarted');
    
    // Salir del chat actual pero mantener la conexión del socket
    // Esto permite volver al chat sin problemas de conexión
    _chatService.leaveCurrentChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat del Viaje'),
            if (!_isConnected)
              Text(
                'Desconectado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        actions: [
          if (_isConnected)
            Icon(
              Icons.circle,
              color: Colors.green,
              size: 12,
            )
          else
            Icon(
              Icons.circle,
              color: Colors.red,
              size: 12,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _initializeChat();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Lista de mensajes
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay mensajes aún',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Envía un mensaje para coordinar\nel punto de encuentro',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.outline,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final isMyMessage = message.userId == authProvider.user?.id;

                                return _buildMessageBubble(message, isMyMessage, theme, colorScheme);
                              },
                            ),
                    ),

                    // Campo de entrada de mensaje
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: 'Escribe un mensaje...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    enabled: _isConnected,
                                  ),
                                  maxLines: null,
                                  textCapitalization: TextCapitalization.sentences,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _isConnected ? _sendMessage : null,
                                icon: const Icon(Icons.send),
                                style: IconButton.styleFrom(
                                  backgroundColor: _isConnected
                                      ? colorScheme.primary
                                      : colorScheme.outline.withValues(alpha: 0.3),
                                  foregroundColor: _isConnected
                                      ? colorScheme.onPrimary
                                      : colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isMyMessage,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: message.userPhoto != 'default_avatar.png'
                  ? NetworkImage(message.userPhoto)
                  : null,
              child: message.userPhoto == 'default_avatar.png'
                  ? Text(
                      message.userName[0].toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMyMessage
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                  bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMyMessage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            message.userName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isMyMessage
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (message.isDriver) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.directions_car,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  Text(
                    message.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMyMessage
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isMyMessage
                          ? colorScheme.onPrimary.withValues(alpha: 0.7)
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: message.userPhoto != 'default_avatar.png'
                  ? NetworkImage(message.userPhoto)
                  : null,
              child: message.userPhoto == 'default_avatar.png'
                  ? Text(
                      message.userName[0].toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}


