// services/socketService.js
const jwt = require('jsonwebtoken');
const Trip = require('../models/Trip');
const User = require('../models/User');
const tripChatService = require('./tripChatService');
const { sendPushNotification } = require('./notificationService');

let io;

const initializeSocket = (socketIoInstance) => {
  io = socketIoInstance;
  
  // Middleware de autenticación para sockets
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];
      
      if (!token) {
        return next(new Error('No se proporcionó token de autenticación'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id).select('-password');
      
      if (!user) {
        return next(new Error('Usuario no encontrado'));
      }

      socket.userId = user._id.toString();
      socket.user = user;
      next();
    } catch (error) {
      console.error('Error en autenticación de socket:', error);
      next(new Error('Token inválido'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`Usuario conectado: ${socket.user.firstName} (${socket.userId}) - Socket: ${socket.id}`);

    // Unirse a la sala de un viaje (con validación de permisos)
    socket.on('joinTripChat', async (tripId, callback) => {
      try {
        const trip = await Trip.findById(tripId)
          .populate('driver', 'firstName lastName profilePhoto')
          .populate('passengers.user', 'firstName lastName profilePhoto');

        if (!trip) {
          const errorResponse = { success: false, message: 'Viaje no encontrado' };
          if (callback) callback(errorResponse);
          socket.emit('joinTripChatResponse', errorResponse);
          return;
        }

        // Verificar que el viaje esté activo (no completado, cancelado o expirado)
        if (['completado', 'cancelado', 'expirado'].includes(trip.status)) {
          const errorResponse = { success: false, message: 'El viaje ya no está activo' };
          if (callback) callback(errorResponse);
          socket.emit('joinTripChatResponse', errorResponse);
          return;
        }

        const userId = socket.userId;
        const isDriver = trip.driver._id.toString() === userId;
        const isConfirmedPassenger = trip.passengers.some(
          p => p.user._id.toString() === userId && p.status === 'confirmed'
        );

        // Solo el conductor o pasajeros confirmados pueden chatear
        if (!isDriver && !isConfirmedPassenger) {
          const errorResponse = { success: false, message: 'No tienes permiso para chatear en este viaje' };
          if (callback) callback(errorResponse);
          socket.emit('joinTripChatResponse', errorResponse);
          return;
        }

        // Asegurar que el chat esté inicializado (por si acaso)
        if (!tripChatService.isChatActive(tripId)) {
          tripChatService.initializeTripChat(tripId, trip.driver._id.toString());
          // Agregar todos los pasajeros confirmados al chat
          trip.passengers
            .filter(p => p.status === 'confirmed')
            .forEach(p => {
              tripChatService.addParticipant(tripId, p.user._id.toString());
            });
        }

        // Agregar al usuario como participante si no está
        tripChatService.addParticipant(tripId, userId);

        // Unirse a la sala del chat del viaje
        const roomName = `trip-chat:${tripId}`;
        socket.join(roomName);
        socket.currentTripId = tripId;

        console.log(`Usuario ${socket.user.firstName} se unió al chat del viaje ${tripId}`);
        
        // Enviar historial de mensajes al usuario que se acaba de unir
        const chatHistory = tripChatService.getChatHistory(tripId);
        if (chatHistory.length > 0) {
          socket.emit('chatHistory', chatHistory);
          console.log(`📜 Historial de ${chatHistory.length} mensajes enviado a ${socket.user.firstName}`);
        }
        
        // Responder con callback si está disponible
        if (callback) callback({ 
          success: true, 
          message: 'Conectado al chat',
          history: chatHistory 
        });
        // También emitir evento de respuesta para compatibilidad
        socket.emit('joinTripChatResponse', { 
          success: true, 
          message: 'Conectado al chat',
          history: chatHistory 
        });
      } catch (error) {
        console.error('Error al unirse al chat:', error);
        const errorResponse = { success: false, message: 'Error al conectar al chat' };
        if (callback) callback(errorResponse);
        socket.emit('joinTripChatResponse', errorResponse);
      }
    });

    // Enviar mensaje de chat
    socket.on('sendChatMessage', async (data, callback) => {
      try {
        const { tripId, message } = data;

        if (!tripId || !message || message.trim().length === 0) {
          const errorResponse = { success: false, message: 'Datos inválidos' };
          if (callback) callback(errorResponse);
          socket.emit('sendChatMessageResponse', errorResponse);
          return;
        }

        // Validar longitud del mensaje
        if (message.length > 500) {
          const errorResponse = { success: false, message: 'El mensaje es demasiado largo (máximo 500 caracteres)' };
          if (callback) callback(errorResponse);
          socket.emit('sendChatMessageResponse', errorResponse);
          return;
        }

        const trip = await Trip.findById(tripId)
          .populate('driver', 'firstName lastName profilePhoto')
          .populate('passengers.user', 'firstName lastName profilePhoto');

        if (!trip) {
          const errorResponse = { success: false, message: 'Viaje no encontrado' };
          if (callback) callback(errorResponse);
          socket.emit('sendChatMessageResponse', errorResponse);
          return;
        }

        // Verificar que el viaje esté activo
        if (['completado', 'cancelado', 'expirado'].includes(trip.status)) {
          const errorResponse = { success: false, message: 'El viaje ya no está activo' };
          if (callback) callback(errorResponse);
          socket.emit('sendChatMessageResponse', errorResponse);
          return;
        }

        const userId = socket.userId;
        const isDriver = trip.driver._id.toString() === userId;
        const isConfirmedPassenger = trip.passengers.some(
          p => p.user._id.toString() === userId && p.status === 'confirmed'
        );

        // Validar permisos
        if (!isDriver && !isConfirmedPassenger) {
          const errorResponse = { success: false, message: 'No tienes permiso para enviar mensajes' };
          if (callback) callback(errorResponse);
          socket.emit('sendChatMessageResponse', errorResponse);
          return;
        }

        // Verificar que el chat esté activo
        if (!tripChatService.isChatActive(tripId)) {
          const errorResponse = { success: false, message: 'El chat de este viaje ya no está activo' };
          if (callback) callback(errorResponse);
          socket.emit('sendChatMessageResponse', errorResponse);
          return;
        }

        // Verificar que el usuario sea participante
        if (!tripChatService.isParticipant(tripId, userId)) {
          const errorResponse = { success: false, message: 'No eres participante de este chat' };
          if (callback) callback(errorResponse);
          socket.emit('sendChatMessageResponse', errorResponse);
          return;
        }

        // Crear objeto de mensaje
        const chatMessage = {
          id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
          tripId: tripId,
          userId: userId,
          userName: socket.user.firstName,
          userPhoto: socket.user.profilePhoto || 'default_avatar.png',
          message: message.trim(),
          timestamp: new Date().toISOString(),
          isDriver: isDriver
        };

        // Guardar mensaje en memoria
        const savedMessage = tripChatService.addMessage(tripId, chatMessage);
        if (!savedMessage) {
          const errorResponse = { success: false, message: 'Error al guardar el mensaje' };
          if (callback) callback(errorResponse);
          socket.emit('sendChatMessageResponse', errorResponse);
          return;
        }

        // Emitir mensaje a todos en la sala del chat (excepto al emisor)
        const roomName = `trip-chat:${tripId}`;
        socket.to(roomName).emit('newChatMessage', chatMessage);
        
        // También enviar al emisor para confirmación
        socket.emit('chatMessageSent', chatMessage);

        // Enviar notificaciones push a todos los participantes del chat (excepto al emisor)
        const participants = tripChatService.getParticipants(tripId);
        const notificationTitle = isDriver 
          ? `💬 ${socket.user.firstName} (Conductor)`
          : `💬 ${socket.user.firstName}`;
        const notificationBody = message.trim().length > 50 
          ? message.trim().substring(0, 50) + '...'
          : message.trim();
        
        // Enviar notificaciones a todos los participantes excepto al emisor
        const notificationPromises = Array.from(participants)
          .filter(participantId => participantId !== userId)
          .map(async (participantId) => {
            try {
              // Asegurar que participantId sea un string
              const participantIdStr = typeof participantId === 'string' 
                ? participantId 
                : (participantId?._id ? participantId._id.toString() : String(participantId));
              
              await sendPushNotification(
                participantIdStr,
                notificationTitle,
                notificationBody,
                {
                  tripId: tripId,
                  type: 'CHAT_MESSAGE',
                  messageId: chatMessage.id,
                  senderName: socket.user.firstName,
                  senderId: userId
                }
              );
            } catch (error) {
              console.error(`Error enviando notificación de chat a ${participantId}:`, error);
            }
          });
        
        // No esperar a que terminen las notificaciones para no bloquear
        Promise.allSettled(notificationPromises).catch(err => {
          console.error('Error en el procesamiento de notificaciones de chat:', err);
        });

        console.log(`Mensaje de chat enviado por ${socket.user.firstName} en viaje ${tripId}`);

        const successResponse = { success: true, message: chatMessage };
        if (callback) callback(successResponse);
        // También emitir evento de respuesta
        socket.emit('sendChatMessageResponse', successResponse);
      } catch (error) {
        console.error('Error al enviar mensaje de chat:', error);
        const errorResponse = { success: false, message: 'Error al enviar mensaje' };
        if (callback) callback(errorResponse);
        socket.emit('sendChatMessageResponse', errorResponse);
      }
    });

    // Salir del chat del viaje
    socket.on('leaveTripChat', (tripId) => {
      const roomName = `trip-chat:${tripId}`;
      socket.leave(roomName);
      if (socket.currentTripId === tripId) {
        socket.currentTripId = null;
      }
      console.log(`Usuario ${socket.user.firstName} salió del chat del viaje ${tripId}`);
    });

    // Mantener compatibilidad con el evento anterior
    socket.on('joinTripRoom', (tripId) => {
      socket.join(tripId);
      console.log(`Socket ${socket.id} se unió a la sala del viaje: ${tripId}`);
    });

    socket.on('disconnect', () => {
      console.log(`Usuario desconectado: ${socket.user?.firstName || 'Desconocido'} (${socket.id})`);
      // Nota: No removemos al usuario del chat al desconectarse
      // El chat permanece activo y puede reconectarse
    });
  });
};

const getIo = () => {
  if (!io) {
    throw new Error("Socket.io no ha sido inicializado!");
  }
  return io;
};

module.exports = { initializeSocket, getIo };