// controllers/dashboardController.js
const User = require('../models/User');
const Trip = require('../models/Trip');
const Rating = require('../models/Rating');

// Obtener estadísticas del dashboard para el usuario
exports.getDashboardStats = async (req, res) => {
    const timestamp = new Date().toISOString();
    const userId = req.user._id;
    
    console.log(`📊 [${timestamp}] Obteniendo estadísticas del dashboard - Usuario: ${userId}`);
    
    try {
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }
        
        const isDriver = user.role === 'driver';
        
        // Obtener estadísticas según el rol
        let stats = {};
        
        if (isDriver) {
            // Estadísticas para conductores
            const [
                totalTrips,
                activeTrips,
                completedTrips,
                totalEarnings,
                averageRating,
                totalRatings
            ] = await Promise.all([
                // Total de viajes creados
                Trip.countDocuments({ driver: userId }),
                
                // Viajes activos (en proceso o esperando)
                Trip.countDocuments({ 
                    driver: userId, 
                    status: { $in: ['esperando', 'completo', 'en-proceso'] }
                }),
                
                // Viajes completados
                Trip.countDocuments({ 
                    driver: userId, 
                    status: 'completado' 
                }),
                
                // Ganancias totales (precio por asiento * asientos ocupados)
                Trip.aggregate([
                    { $match: { driver: userId, status: 'completado' } },
                    { $group: { 
                        _id: null, 
                        totalEarnings: { $sum: { $multiply: ['$pricePerSeat', '$seatsBooked'] } }
                    }}
                ]),
                
                // Calificación promedio
                Rating.aggregate([
                    { $match: { rated: userId, ratingType: 'driver' } },
                    { $group: { _id: null, averageRating: { $avg: '$rating' } } }
                ]),
                
                // Total de calificaciones
                Rating.countDocuments({ rated: userId, ratingType: 'driver' })
            ]);
            
            const earnings = totalEarnings.length > 0 ? totalEarnings[0].totalEarnings : 0;
            const avgRating = averageRating.length > 0 ? averageRating[0].averageRating : 0;
            
            stats = {
                totalTrips,
                activeTrips,
                completedTrips,
                totalEarnings: earnings,
                averageRating: Math.round(avgRating * 10) / 10,
                totalRatings,
                points: Math.floor(earnings * 0.1), // 1 punto por cada S/. 0.10 ganado
                savings: 0 // Los conductores no ahorran, ganan
            };
            
        } else {
            // Estadísticas para pasajeros
            const [
                totalBookings,
                activeBookings,
                completedBookings,
                totalSpent,
                averageRating,
                totalRatings
            ] = await Promise.all([
                // Total de reservas realizadas
                Trip.countDocuments({ 
                    'passengers.user': userId 
                }),
                
                // Reservas activas
                Trip.countDocuments({ 
                    'passengers.user': userId,
                    'passengers.status': { $in: ['confirmed', 'pending'] },
                    status: { $in: ['esperando', 'completo', 'en-proceso'] }
                }),
                
                // Reservas completadas
                Trip.countDocuments({ 
                    'passengers.user': userId,
                    'passengers.status': 'confirmed',
                    status: 'completado'
                }),
                
                // Total gastado
                Trip.aggregate([
                    { $match: { 'passengers.user': userId, status: 'completado' } },
                    { $unwind: '$passengers' },
                    { $match: { 'passengers.user': userId } },
                    { $group: { 
                        _id: null, 
                        totalSpent: { $sum: '$pricePerSeat' }
                    }}
                ]),
                
                // Calificación promedio como pasajero
                Rating.aggregate([
                    { $match: { rated: userId, ratingType: 'passenger' } },
                    { $group: { _id: null, averageRating: { $avg: '$rating' } } }
                ]),
                
                // Total de calificaciones como pasajero
                Rating.countDocuments({ rated: userId, ratingType: 'passenger' })
            ]);
            
            const spent = totalSpent.length > 0 ? totalSpent[0].totalSpent : 0;
            const avgRating = averageRating.length > 0 ? averageRating[0].averageRating : 0;
            
            // Calcular ahorro estimado (asumiendo que un taxi costaría 3x más)
            const estimatedTaxiCost = spent * 3;
            const savings = estimatedTaxiCost - spent;
            
            stats = {
                totalBookings,
                activeBookings,
                completedBookings,
                totalSpent: spent,
                averageRating: Math.round(avgRating * 10) / 10,
                totalRatings,
                points: Math.floor(spent * 0.05), // 1 punto por cada S/. 0.20 gastado
                savings: Math.max(0, savings)
            };
        }
        
        console.log(`✅ [${timestamp}] Estadísticas obtenidas exitosamente`);
        console.log(`   📊 Rol: ${isDriver ? 'Conductor' : 'Pasajero'}`);
        console.log(`   📈 Estadísticas: ${JSON.stringify(stats)}`);
        
        res.json({
            success: true,
            user: {
                _id: user._id,
                firstName: user.firstName,
                lastName: user.lastName,
                role: user.role,
                averageRating: user.averageRating,
                totalRatings: user.totalRatings
            },
            stats,
            isDriver
        });
        
    } catch (error) {
        console.error('═══════════════════════════════════════════════════════');
        console.error(`🔴 ERROR AL OBTENER ESTADÍSTICAS [${timestamp}]`);
        console.error(`📝 Mensaje: ${error.message}`);
        console.error(`📋 Stack: ${error.stack}`);
        console.error('═══════════════════════════════════════════════════════');
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};

// Obtener viajes recientes del usuario
exports.getRecentTrips = async (req, res) => {
    const timestamp = new Date().toISOString();
    const userId = req.user._id;
    const limit = parseInt(req.query.limit) || 5;
    
    console.log(`📋 [${timestamp}] Obteniendo viajes recientes - Usuario: ${userId}, Límite: ${limit}`);
    
    try {
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }
        
        const isDriver = user.role === 'driver';
        let trips = [];
        
        if (isDriver) {
            // Viajes como conductor
            trips = await Trip.find({ driver: userId })
                .populate('passengers.user', 'firstName lastName email')
                .sort({ createdAt: -1 })
                .limit(limit);
        } else {
            // Viajes como pasajero
            trips = await Trip.find({ 'passengers.user': userId })
                .populate('driver', 'firstName lastName email averageRating')
                .sort({ createdAt: -1 })
                .limit(limit);
        }
        
        // Formatear los viajes para la respuesta
        const formattedTrips = trips.map(trip => ({
            _id: trip._id,
            origin: trip.origin,
            destination: trip.destination,
            departureTime: trip.departureTime,
            status: trip.status,
            pricePerSeat: trip.pricePerSeat,
            availableSeats: trip.availableSeats,
            seatsBooked: trip.seatsBooked,
            createdAt: trip.createdAt,
            // Información específica según el rol
            ...(isDriver ? {
                passengers: trip.passengers.map(p => ({
                    user: p.user,
                    status: p.status,
                    bookedAt: p.bookedAt
                }))
            } : {
                driver: trip.driver,
                myBooking: trip.passengers.find(p => p.user.toString() === userId.toString())
            })
        }));
        
        console.log(`✅ [${timestamp}] Viajes recientes obtenidos: ${formattedTrips.length}`);
        
        res.json({
            success: true,
            trips: formattedTrips,
            isDriver
        });
        
    } catch (error) {
        console.error('═══════════════════════════════════════════════════════');
        console.error(`🔴 ERROR AL OBTENER VIAJES RECIENTES [${timestamp}]`);
        console.error(`📝 Mensaje: ${error.message}`);
        console.error(`📋 Stack: ${error.stack}`);
        console.error('═══════════════════════════════════════════════════════');
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};



