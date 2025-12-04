// controllers/tripController.js
const mongoose = require('mongoose');
const Trip = require('../models/Trip');
const User = require('../models/User');
const { sendPushNotification } = require('../services/notificationService');
const { getIo } = require('../services/socketService');
const tripChatService = require('../services/tripChatService');

// Helper para validar ObjectId
const isValidObjectId = (id) => {
    return mongoose.Types.ObjectId.isValid(id);
};

// @desc    Crear un nuevo viaje
// @route   POST /api/trips
// @access  Private/Driver
exports.createTrip = async (req, res) => {
    try {
        const { origin, destination, departureTime, availableSeats, pricePerSeat, description } = req.body;

        // Validar datos requeridos
        if (!origin || !destination || !departureTime || !availableSeats || !pricePerSeat) {
            return res.status(400).json({ 
                message: 'Faltan campos requeridos: origin, destination, departureTime, availableSeats, pricePerSeat' 
            });
        }

        // Validar tipos de datos
        if (typeof availableSeats !== 'number' || availableSeats < 1 || availableSeats > 20) {
            return res.status(400).json({ 
                message: 'availableSeats debe ser un número entre 1 y 20' 
            });
        }

        if (typeof pricePerSeat !== 'number' || pricePerSeat < 0) {
            return res.status(400).json({ 
                message: 'pricePerSeat debe ser un número positivo' 
            });
        }

        // Verificar que sea conductor
        if (req.user.role !== 'driver') {
          return res.status(403).json({ message: 'Solo conductores pueden crear viajes' });
        }

        // Verificar que el conductor esté aprobado
        if (req.user.driverApprovalStatus !== 'approved') {
          if (req.user.driverApprovalStatus === 'pending') {
            return res.status(403).json({ 
              message: 'Tu solicitud está siendo revisada. Este proceso toma un promedio de 24 a 48 horas. Te notificaremos cuando sea aprobada.' 
            });
          } else if (req.user.driverApprovalStatus === 'rejected') {
            return res.status(403).json({ 
              message: 'Tu solicitud fue rechazada. Por favor, corrige tus documentos desde tu perfil y vuelve a enviarlos para revisión.' 
            });
          } else {
            return res.status(403).json({ 
              message: 'Debes completar tu perfil de conductor y ser aprobado por un administrador antes de poder crear viajes.' 
            });
          }
        }

        // Verificar si el conductor ya tiene un viaje activo
        // Un viaje está activo si está en: esperando, completo, o en-proceso
        // Y no ha expirado (si tiene expiresAt)
        const existingTrip = await Trip.findOne({
          driver: req.user._id,
          status: { $in: ['esperando', 'completo', 'en-proceso'] },
          $or: [
            { expiresAt: { $gt: new Date() } },
            { expiresAt: null },
            { status: 'en-proceso' } // Los viajes en proceso no expiran
          ]
        });

        if (existingTrip) {
          return res.status(400).json({ 
            message: 'Ya tienes un viaje activo. Debes esperar a que expire o completar el actual antes de crear uno nuevo.' 
          });
        }

        // Calcular tiempo de expiración: 10 minutos desde ahora
        const expiresAt = new Date();
        expiresAt.setMinutes(expiresAt.getMinutes() + 10);

        const trip = new Trip({
            driver: req.user._id,
            origin,
            destination,
            departureTime,
            expiresAt, // Viaje expira en 10 minutos
            availableSeats,
            pricePerSeat,
            description
        });

        const createdTrip = await trip.save();
        
        // Poblar información del conductor y pasajeros
        await createdTrip.populate('driver', 'firstName lastName profilePhoto');
        await createdTrip.populate('passengers.user', 'firstName lastName university profilePhoto');
        
        console.log(`Viaje creado y poblado: ${createdTrip._id}`);
        
        // Inicializar el chat del viaje
        tripChatService.initializeTripChat(createdTrip._id.toString(), req.user._id.toString());
        
        // --- LÓGICA DE NOTIFICACIÓN DE NUEVO VIAJE ---
        // Emitir evento global para actualización en tiempo real
        getIo().emit('newTripAvailable', {
            trip: createdTrip,
            message: `Nuevo viaje disponible de ${origin.name} a ${destination.name}`
        });
        
        // Notificar a todos los pasajeros activos sobre el nuevo viaje
        const passengers = await User.find({ role: 'passenger', fcmToken: { $exists: true, $ne: null } });
        
        const notificationTitle = '🚗 Nuevo Viaje Disponible';
        const notificationBody = `${req.user.firstName} ofrece viaje de ${origin.name} a ${destination.name} por S/. ${pricePerSeat.toFixed(2)}`;
        
        // Enviar notificaciones push a todos los pasajeros
        // Usar Promise.allSettled para enviar todas las notificaciones en paralelo
        const notificationPromises = passengers.map(async (passenger) => {
            try {
                await sendPushNotification(
                    passenger._id.toString(),
                    notificationTitle,
                    notificationBody,
                    {
                        tripId: createdTrip._id.toString(),
                        type: 'NEW_TRIP_AVAILABLE',
                        origin: origin.name,
                        destination: destination.name,
                        price: pricePerSeat.toString(),
                        driverName: req.user.firstName
                    }
                );
            } catch (error) {
                console.error(`Error enviando notificación a ${passenger._id}:`, error);
            }
        });
        // No esperamos a que terminen las notificaciones para no bloquear la respuesta
        Promise.allSettled(notificationPromises).catch(err => {
            console.error('Error en el procesamiento de notificaciones:', err);
        });

        console.log(`Viaje creado: ${createdTrip._id}, expira en 10 minutos a las ${expiresAt.toLocaleTimeString()}`);
        
        // Programar auto-expiración del viaje después de 10 minutos
        // NOTA: El setTimeout se ejecutará solo si el servidor sigue corriendo
        // En producción, considera usar un job scheduler (como node-cron o agenda)
        // para manejar expiraciones de forma más confiable
        setTimeout(async () => {
            try {
                const tripToExpire = await Trip.findById(createdTrip._id);
                // Solo expirar si está en 'esperando' o 'completo' (no iniciado ni completado)
                if (tripToExpire && ['esperando', 'completo'].includes(tripToExpire.status)) {
                    tripToExpire.status = 'expirado';
                    await tripToExpire.save();
                    console.log(`Viaje ${createdTrip._id} marcado como expirado automáticamente`);
                    
                    // Cerrar el chat del viaje
                    tripChatService.closeTripChat(createdTrip._id.toString());
                    
                    // Notificar a todos los participantes del chat que el viaje expiró
                    const roomName = `trip-chat:${createdTrip._id}`;
                    getIo().to(roomName).emit('tripChatClosed', {
                      tripId: createdTrip._id.toString(),
                      reason: 'expirado'
                    });
                    
                    // Notificar que el viaje expiró
                    getIo().emit('tripExpired', { tripId: createdTrip._id.toString() });
                }
            } catch (error) {
                console.error(`Error al expirar viaje ${createdTrip._id}:`, error);
            }
        }, 10 * 60 * 1000); // 10 minutos en milisegundos

        res.status(201).json(createdTrip);
    } catch (error) {
        console.error('Error en createTrip:', error);
        // No exponer detalles del error en producción
        const errorMessage = process.env.NODE_ENV === 'production' 
            ? 'Error al crear el viaje' 
            : error.message;
        res.status(500).json({ message: `Error del servidor: ${errorMessage}` });
    }
};

// @desc    Obtener todos los viajes disponibles
// @route   GET /api/trips
// @access  Private
exports.getAvailableTrips = async (req, res) => {
    try {
        const now = new Date();
        
        // Filtrar viajes activos que no hayan expirado
        // Incluir 'esperando' y 'completo' porque ambos pueden aceptar solicitudes
        // (si alguien sale de un viaje completo, vuelve a esperando)
        const trips = await Trip.find({ 
            status: { $in: ['esperando', 'completo'] }, 
            expiresAt: { $gt: now } // Solo viajes que aún no expiraron
        })
            .populate('driver', 'firstName lastName profilePhoto')
            .populate('passengers.user', 'firstName lastName university profilePhoto')
            .sort({ createdAt: -1 }); // Más recientes primero
        
        res.json(trips);
    } catch (error) {
        console.error('Error en getAvailableTrips:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};


// @desc    Obtener un viaje por su ID
// @route   GET /api/trips/:id
// @access  Private
exports.getTripById = async (req, res) => {
    try {
        // Validar ObjectId
        if (!isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: 'ID de viaje inválido' });
        }

        const trip = await Trip.findById(req.params.id)
            .populate('driver', 'firstName lastName profilePhoto vehicle')
            .populate('passengers.user', 'firstName lastName profilePhoto');

        if (!trip) {
            return res.status(404).json({ message: 'Viaje no encontrado' });
        }

        res.json(trip);
    } catch (error) {
        console.error('Error en getTripById:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};


// @desc    Pasajero solicita unirse (pendiente de aprobación)
// @route   POST /api/trips/:id/book
// @access  Private
exports.requestBooking = async (req, res) => {
    try {
        // Validar ObjectId
        if (!isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: 'ID de viaje inválido' });
        }

        const trip = await Trip.findById(req.params.id);

        if (!trip) {
            return res.status(404).json({ message: 'Viaje no encontrado' });
        }

        if (trip.driver.toString() === req.user._id.toString()) {
            return res.status(400).json({ message: 'No puedes reservar en tu propio viaje' });
        }

        // Verificar que el viaje esté en un estado que acepta reservas
        if (!['esperando', 'completo'].includes(trip.status)) {
            return res.status(400).json({ 
                message: 'Este viaje no está activo para reservas. Solo puedes reservar en viajes que están esperando pasajeros o completos.' 
            });
        }
        
        // Verificar que el viaje no haya expirado
        if (trip.expiresAt && new Date() > trip.expiresAt) {
            return res.status(400).json({ message: 'Este viaje ha expirado' });
        }

        // Verificar si ya tiene una solicitud
        const existingRequest = trip.passengers.find(p => p.user.toString() === req.user._id.toString());
        
        if (existingRequest) {
            // Si está confirmado, no puede volver a solicitar
            if (existingRequest.status === 'confirmed') {
                return res.status(400).json({ message: 'Ya estás confirmado en este viaje' });
            }
            // Si está pendiente, no puede volver a solicitar
            if (existingRequest.status === 'pending') {
                return res.status(400).json({ message: 'Ya tienes una solicitud pendiente para este viaje' });
            }
            // Si fue rechazado, permitir que vuelva a solicitar (actualizar a pending)
            if (existingRequest.status === 'rejected') {
                existingRequest.status = 'pending';
                existingRequest.bookedAt = new Date();
            }
        } else {
            // Agregar como pendiente (no descuenta cupo aún)
            trip.passengers.push({ user: req.user._id, status: 'pending' });
        }

        await trip.save();

        // Notificar al conductor
        const driverId = trip.driver.toString();
        const notificationTitle = 'Nueva Solicitud de Viaje';
        const notificationBody = existingRequest && existingRequest.status === 'rejected'
            ? `${req.user.firstName} volvió a solicitar unirse a tu viaje a ${trip.destination.name}.`
            : `${req.user.firstName} quiere unirse a tu viaje a ${trip.destination.name}.`;
        
        try {
            await sendPushNotification(driverId, notificationTitle, notificationBody, { 
                tripId: trip._id.toString(), 
                type: 'NEW_BOOKING_REQUEST' 
            });
            getIo().to(driverId).emit('newBookingRequest', { 
                message: notificationBody,
                tripId: trip._id.toString(),
                passenger: { _id: req.user._id, firstName: req.user.firstName }
            });
        } catch (notificationError) {
            console.error('Error enviando notificación al conductor:', notificationError);
            // No fallar la solicitud si la notificación falla
        }

        res.status(201).json({ message: 'Solicitud enviada. Espera aprobación del conductor.' });

    } catch (error) {
        console.error('Error en requestBooking:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};


// @desc    Conductor gestiona una solicitud (aceptar/rechazar)
// @route   PUT /api/trips/:tripId/bookings/:passengerId
// @access  Private/Driver
exports.manageBooking = async (req, res) => {
    const { status } = req.body;
    const { tripId, passengerId } = req.params;

    if (!['confirmed', 'rejected'].includes(status)) {
        return res.status(400).json({ message: "Estado inválido. Debe ser 'confirmed' o 'rejected'." });
    }

    try {
        // Validar ObjectIds
        if (!isValidObjectId(tripId) || !isValidObjectId(passengerId)) {
            return res.status(400).json({ message: 'ID de viaje o pasajero inválido' });
        }

        const trip = await Trip.findById(tripId);
        if (!trip) {
            return res.status(404).json({ message: 'Viaje no encontrado' });
        }

        if (trip.driver.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'No autorizado para gestionar este viaje' });
        }

        const passengerRequest = trip.passengers.find(p => p.user.toString() === passengerId && p.status === 'pending');
        if (!passengerRequest) {
            return res.status(404).json({ message: 'Solicitud de pasajero no encontrada o ya gestionada' });
        }

        let notificationTitle = 'Solicitud Actualizada';
        let notificationBody = '';

        if (status === 'confirmed') {
            if (trip.seatsBooked >= trip.availableSeats) {
                return res.status(400).json({ message: 'El viaje ya está lleno' });
            }
            passengerRequest.status = 'confirmed';
            trip.seatsBooked += 1;
            
            // Si el viaje se llena completamente, cambiar a estado 'completo'
            // Si estaba en 'esperando' y ahora está lleno, cambiar a 'completo'
            if (trip.seatsBooked === trip.availableSeats && trip.status === 'esperando') {
                trip.status = 'completo';
            }
            
            // Agregar pasajero al chat del viaje
            tripChatService.addParticipant(tripId, passengerId);
            
            notificationBody = `¡Tu solicitud para el viaje a ${trip.destination.name} ha sido aceptada!`;
        } else { // 'rejected'
            passengerRequest.status = 'rejected';
            notificationBody = `Tu solicitud para el viaje a ${trip.destination.name} ha sido rechazada.`;
        }

        const updatedTrip = await trip.save();
        
        // Notificar al pasajero
        try {
            await sendPushNotification(passengerId, notificationTitle, notificationBody, { 
                tripId: tripId, 
                type: 'BOOKING_STATUS_UPDATE' 
            });
            getIo().to(passengerId).emit('bookingStatusChanged', {
                message: notificationBody,
                tripId: tripId,
                status: status
            });
        } catch (notificationError) {
            console.error('Error enviando notificación al pasajero:', notificationError);
            // No fallar la operación si la notificación falla
        }
        
        // Notificar al conductor para actualizar su UI
        getIo().to(trip.driver.toString()).emit('tripUpdated', updatedTrip);

        res.json(updatedTrip);

    } catch (error) {
        console.error('Error en manageBooking:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};


// @desc    Obtener los viajes que un usuario ha creado como conductor
// @route   GET /api/trips/my-driver-trips
// @access  Private/Driver
exports.getMyDriverTrips = async (req, res) => {
    try {
        // Obtener viajes del conductor
        // Incluir solo viajes relevantes: en proceso, completados, esperando, completo
        // Excluir: expirados y cancelados
        const trips = await Trip.find({ 
            driver: req.user._id,
            status: { $in: ['en-proceso', 'completado', 'esperando', 'completo'] }
        })
            .populate('driver', 'firstName lastName profilePhoto')
            .populate('passengers.user', 'firstName lastName university profilePhoto phone')
            .sort({ createdAt: -1 });
        
        res.json(trips);
    } catch (error) {
        console.error('Error en getMyDriverTrips:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};

// @desc    Obtener las reservas que un usuario ha hecho como pasajero
// @route   GET /api/trips/my-passenger-trips
// @access  Private
exports.getMyPassengerTrips = async (req, res) => {
    try {
        // Obtener viajes donde el usuario es pasajero confirmado
        // Incluir solo viajes relevantes: en proceso, completados, esperando, completo
        // Excluir: expirados y cancelados
        const trips = await Trip.find({ 
            'passengers.user': req.user._id,
            'passengers.status': 'confirmed',
            status: { $in: ['en-proceso', 'completado', 'esperando', 'completo'] }
        })
            .populate('driver', 'firstName lastName vehicle')
            .populate('passengers.user', 'firstName lastName university profilePhoto')
            .sort({ createdAt: -1 });
        
        res.json(trips);
    } catch (error) {
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};

// @desc    Iniciar un viaje (solo si hay al menos 1 pasajero confirmado)
// @route   PUT /api/trips/:id/start
// @access  Private/Driver
exports.startTrip = async (req, res) => {
    try {
        // Validar ObjectId
        if (!isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: 'ID de viaje inválido' });
        }

        const trip = await Trip.findById(req.params.id);

        if (!trip) {
            return res.status(404).json({ message: 'Viaje no encontrado' });
        }

        // Verificar que el usuario es el conductor
        if (trip.driver.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'No autorizado. Solo el conductor puede iniciar el viaje.' });
        }

        // Verificar que el viaje esté en un estado que permite iniciarlo
        // Solo se puede iniciar si está en 'esperando' o 'completo' (no iniciado, no cancelado, no expirado)
        if (!['esperando', 'completo'].includes(trip.status)) {
            return res.status(400).json({ 
                message: `El viaje no puede ser iniciado. Estado actual: ${trip.status}. Solo puedes iniciar viajes que están esperando pasajeros o completos.` 
            });
        }
        
        // Verificar que el viaje no haya expirado
        if (trip.expiresAt && new Date() > trip.expiresAt) {
            return res.status(400).json({ message: 'No puedes iniciar un viaje que ha expirado' });
        }

        // Verificar que haya al menos un pasajero confirmado
        const confirmedPassengers = trip.passengers.filter(p => p.status === 'confirmed');
        if (confirmedPassengers.length === 0) {
            return res.status(400).json({ message: 'No puedes iniciar el viaje sin pasajeros confirmados' });
        }

        // Cambiar estado a en-proceso
        trip.status = 'en-proceso';
        const updatedTrip = await trip.save();

        // Poblar datos
        await updatedTrip.populate('driver', 'firstName lastName profilePhoto vehicle');
        await updatedTrip.populate('passengers.user', 'firstName lastName university profilePhoto phone');

        // Notificar a los pasajeros confirmados
        const notificationTitle = '🚗 Viaje Iniciado';
        const notificationBody = `${req.user.firstName} ha iniciado el viaje a ${trip.destination.name}`;
        
        // Enviar notificaciones a todos los pasajeros confirmados
        const startNotificationPromises = confirmedPassengers.map(async (passenger) => {
            try {
                await sendPushNotification(
                    passenger.user.toString(),
                    notificationTitle,
                    notificationBody,
                    { tripId: trip._id.toString(), type: 'TRIP_STARTED' }
                );
                getIo().to(passenger.user.toString()).emit('tripStarted', {
                    message: notificationBody,
                    tripId: trip._id.toString(),
                });
            } catch (error) {
                console.error(`Error notificando a pasajero ${passenger.user}:`, error);
            }
        });
        Promise.allSettled(startNotificationPromises).catch(err => {
            console.error('Error en el procesamiento de notificaciones de inicio:', err);
        });

        console.log(`Viaje ${trip._id} iniciado por conductor ${req.user._id}`);
        res.json(updatedTrip);

    } catch (error) {
        console.error('Error en startTrip:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};

// @desc    Cancelar un viaje (solo si no hay pasajeros confirmados)
// @route   PUT /api/trips/:id/cancel
// @access  Private/Driver
exports.cancelTrip = async (req, res) => {
    try {
        // Validar ObjectId
        if (!isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: 'ID de viaje inválido' });
        }

        const { cancellationReason } = req.body;
        const trip = await Trip.findById(req.params.id);

        if (!trip) {
            return res.status(404).json({ message: 'Viaje no encontrado' });
        }

        // Verificar que el usuario es el conductor
        if (trip.driver.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'No autorizado. Solo el conductor puede cancelar el viaje.' });
        }

        // Verificar que el viaje esté en un estado cancelable
        if (!['esperando', 'completo'].includes(trip.status)) {
            return res.status(400).json({ message: 'El viaje no puede ser cancelado en su estado actual' });
        }

        // Obtener pasajeros confirmados
        const confirmedPassengers = trip.passengers.filter(p => p.status === 'confirmed');
        
        // Si hay pasajeros confirmados, verificar si alguno ya está en el vehículo
        if (confirmedPassengers.length > 0) {
            const passengersInVehicle = confirmedPassengers.filter(p => p.inVehicle === true);
            
            // NO se puede cancelar si hay pasajeros que ya están en el vehículo
            if (passengersInVehicle.length > 0) {
                return res.status(400).json({ 
                    message: 'No puedes cancelar el viaje porque hay pasajeros que ya están en el vehículo.' 
                });
            }
            
            // Si hay pasajeros confirmados pero NO están en el vehículo, se requiere motivo
            if (!cancellationReason || cancellationReason.trim().length === 0) {
                return res.status(400).json({ 
                    message: 'Debes proporcionar un motivo de cancelación cuando hay pasajeros confirmados.' 
                });
            }
        }

        // Cambiar estado a cancelado
        trip.status = 'cancelado';
        const updatedTrip = await trip.save();
        
        // Cerrar el chat del viaje
        tripChatService.closeTripChat(trip._id.toString());
        
        // Notificar a todos los participantes del chat que el viaje fue cancelado
        const roomName = `trip-chat:${trip._id}`;
        getIo().to(roomName).emit('tripChatClosed', {
          tripId: trip._id.toString(),
          reason: 'cancelado'
        });

        // Notificar a todos los pasajeros (pendientes y confirmados)
        const allPassengers = trip.passengers.filter(p => p.status === 'pending' || p.status === 'confirmed');
        const notificationTitle = '❌ Viaje Cancelado';
        let notificationBody = `El viaje a ${trip.destination.name} ha sido cancelado por el conductor`;
        
        // Agregar motivo si existe
        if (cancellationReason && cancellationReason.trim().length > 0) {
            notificationBody += `. Motivo: ${cancellationReason}`;
        }
        
        // Enviar notificaciones a todos los pasajeros
        const cancelNotificationPromises = allPassengers.map(async (passenger) => {
            try {
                await sendPushNotification(
                    passenger.user.toString(),
                    notificationTitle,
                    notificationBody,
                    { tripId: trip._id.toString(), type: 'TRIP_CANCELLED' }
                );
                getIo().to(passenger.user.toString()).emit('tripCancelled', {
                    message: notificationBody,
                    tripId: trip._id.toString(),
                    reason: cancellationReason || null
                });
            } catch (error) {
                console.error(`Error notificando a pasajero ${passenger.user}:`, error);
            }
        });
        Promise.allSettled(cancelNotificationPromises).catch(err => {
            console.error('Error en el procesamiento de notificaciones de cancelación:', err);
        });

        console.log(`Viaje ${trip._id} cancelado por conductor ${req.user._id}${cancellationReason ? ` con motivo: ${cancellationReason}` : ''}`);
        res.json({ 
            message: 'Viaje cancelado exitosamente', 
            trip: updatedTrip 
        });

    } catch (error) {
        console.error('Error en cancelTrip:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};

// @desc    Pasajero cancela su participación en un viaje antes de que inicie
// @route   DELETE /api/trips/:id/leave
// @access  Private
exports.leaveTrip = async (req, res) => {
    try {
        // Validar ObjectId
        if (!isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: 'ID de viaje inválido' });
        }

        const trip = await Trip.findById(req.params.id);

        if (!trip) {
            return res.status(404).json({ message: 'Viaje no encontrado' });
        }

        // Verificar que el viaje esté en un estado que permite salir
        // Solo se puede salir de viajes en 'esperando' o 'completo' (antes de iniciar)
        if (!['esperando', 'completo'].includes(trip.status)) {
            const statusMessages = {
                'en-proceso': 'No puedes salir de un viaje que ya ha iniciado',
                'completado': 'No puedes salir de un viaje que ya ha sido completado',
                'expirado': 'No puedes salir de un viaje que ya ha expirado',
                'cancelado': 'No puedes salir de un viaje que ya ha sido cancelado'
            };
            return res.status(400).json({ 
                message: statusMessages[trip.status] || `No puedes salir de este viaje. Estado actual: ${trip.status}` 
            });
        }

        // Buscar al pasajero en la lista
        const passengerIndex = trip.passengers.findIndex(
            p => p.user.toString() === req.user._id.toString() && p.status === 'confirmed'
        );

        if (passengerIndex === -1) {
            return res.status(404).json({ message: 'No estás confirmado en este viaje' });
        }

        // Remover al pasajero de la lista
        trip.passengers.splice(passengerIndex, 1);
        
        // Disminuir el contador de asientos reservados
        if (trip.seatsBooked > 0) {
            trip.seatsBooked -= 1;
        }

        // Si el viaje estaba completo y ahora hay espacio, volver a esperando
        if (trip.status === 'completo' && trip.seatsBooked < trip.availableSeats) {
            trip.status = 'esperando';
        }

        const updatedTrip = await trip.save();
        
        // Remover pasajero del chat del viaje
        tripChatService.removeParticipant(trip._id.toString(), req.user._id.toString());
        
        // Notificar al chat que el pasajero abandonó
        const roomName = `trip-chat:${trip._id}`;
        getIo().to(roomName).emit('passengerLeftChat', {
          tripId: trip._id.toString(),
          passengerId: req.user._id.toString(),
          passengerName: req.user.firstName
        });

        // Notificar al conductor
        const notificationTitle = '⚠️ Pasajero Canceló';
        const notificationBody = `${req.user.firstName} ha cancelado su participación en el viaje a ${trip.destination.name}`;
        
        try {
            await sendPushNotification(
                trip.driver.toString(),
                notificationTitle,
                notificationBody,
                { tripId: trip._id.toString(), type: 'PASSENGER_LEFT' }
            );
            getIo().to(trip.driver.toString()).emit('passengerLeft', {
                message: notificationBody,
                tripId: trip._id.toString(),
                passengerId: req.user._id.toString(),
            });
        } catch (error) {
            console.error(`Error notificando al conductor:`, error);
        }

        console.log(`Pasajero ${req.user._id} canceló participación en viaje ${trip._id}`);
        res.json({ message: 'Has salido del viaje exitosamente', trip: updatedTrip });

    } catch (error) {
        console.error('Error en leaveTrip:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};

// @desc    Finalizar un viaje (solo si está en curso)
// @route   PUT /api/trips/:id/complete
// @access  Private/Driver
exports.completeTrip = async (req, res) => {
    try {
        // Validar ObjectId
        if (!isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: 'ID de viaje inválido' });
        }

        const trip = await Trip.findById(req.params.id);

        if (!trip) {
            return res.status(404).json({ message: 'Viaje no encontrado' });
        }

        // Verificar que el usuario es el conductor
        if (trip.driver.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'No autorizado. Solo el conductor puede finalizar el viaje.' });
        }

        // Verificar que el viaje esté en curso (en-proceso)
        // Solo se puede completar un viaje que está en proceso
        if (trip.status !== 'en-proceso') {
            return res.status(400).json({ 
                message: `Solo se pueden finalizar viajes que están en curso. Estado actual: ${trip.status}` 
            });
        }

        // Cambiar estado a completado (viaje finalizado exitosamente)
        trip.status = 'completado';
        const updatedTrip = await trip.save();
        
        // Cerrar el chat del viaje
        tripChatService.closeTripChat(trip._id.toString());
        
        // Notificar a todos los participantes del chat que el viaje fue completado
        const roomName = `trip-chat:${trip._id}`;
        getIo().to(roomName).emit('tripChatClosed', {
          tripId: trip._id.toString(),
          reason: 'completado'
        });

        // Poblar datos
        await updatedTrip.populate('driver', 'firstName lastName profilePhoto vehicle');
        await updatedTrip.populate('passengers.user', 'firstName lastName university profilePhoto phone');

        // Notificar a los pasajeros confirmados
        const confirmedPassengers = trip.passengers.filter(p => p.status === 'confirmed');
        const notificationTitle = '🎉 Viaje Completado';
        const notificationBody = `${req.user.firstName} ha completado el viaje a ${trip.destination.name}. ¡Gracias por viajar con nosotros!`;
        
        // Enviar notificaciones a todos los pasajeros confirmados
        const completeNotificationPromises = confirmedPassengers.map(async (passenger) => {
            try {
                await sendPushNotification(
                    passenger.user.toString(),
                    notificationTitle,
                    notificationBody,
                    { tripId: trip._id.toString(), type: 'TRIP_COMPLETED' }
                );
                getIo().to(passenger.user.toString()).emit('tripCompleted', {
                    message: notificationBody,
                    tripId: trip._id.toString(),
                });
            } catch (error) {
                console.error(`Error notificando a pasajero ${passenger.user}:`, error);
            }
        });
        Promise.allSettled(completeNotificationPromises).catch(err => {
            console.error('Error en el procesamiento de notificaciones de completado:', err);
        });

        console.log(`Viaje ${trip._id} completado por conductor ${req.user._id}`);
        res.json(updatedTrip);

    } catch (error) {
        console.error('Error en completeTrip:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};

// @desc    Pasajero confirma que está en el vehículo
// @route   PUT /api/trips/:id/confirm-in-vehicle
// @access  Private
exports.confirmInVehicle = async (req, res) => {
    try {
        // Validar ObjectId
        if (!isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: 'ID de viaje inválido' });
        }

        const trip = await Trip.findById(req.params.id);

        if (!trip) {
            return res.status(404).json({ message: 'Viaje no encontrado' });
        }

        // Verificar que el viaje esté en proceso
        if (trip.status !== 'en-proceso') {
            return res.status(400).json({ 
                message: 'Solo puedes confirmar que estás en el vehículo cuando el viaje está en proceso' 
            });
        }

        // Buscar al pasajero en la lista
        const passenger = trip.passengers.find(
            p => p.user.toString() === req.user._id.toString() && p.status === 'confirmed'
        );

        if (!passenger) {
            return res.status(404).json({ message: 'No estás confirmado en este viaje' });
        }

        // Verificar si ya confirmó
        if (passenger.inVehicle) {
            return res.status(400).json({ message: 'Ya confirmaste que estás en el vehículo' });
        }

        // Marcar que el pasajero está en el vehículo
        passenger.inVehicle = true;
        const updatedTrip = await trip.save();

        // Poblar datos
        await updatedTrip.populate('driver', 'firstName lastName profilePhoto vehicle');
        await updatedTrip.populate('passengers.user', 'firstName lastName university profilePhoto phone');

        // Notificar al conductor
        const notificationTitle = '✅ Pasajero en el Vehículo';
        const notificationBody = `${req.user.firstName} ha confirmado que está en el vehículo`;
        
        try {
            await sendPushNotification(
                trip.driver.toString(),
                notificationTitle,
                notificationBody,
                { tripId: trip._id.toString(), type: 'PASSENGER_IN_VEHICLE' }
            );
            getIo().to(trip.driver.toString()).emit('passengerInVehicle', {
                message: notificationBody,
                tripId: trip._id.toString(),
                passengerId: req.user._id.toString(),
            });
        } catch (error) {
            console.error(`Error notificando al conductor:`, error);
        }

        // Notificar actualización del viaje
        getIo().to(trip._id.toString()).emit('tripUpdated', updatedTrip);

        console.log(`Pasajero ${req.user._id} confirmó que está en el vehículo del viaje ${trip._id}`);
        res.json(updatedTrip);

    } catch (error) {
        console.error('Error en confirmInVehicle:', error);
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};