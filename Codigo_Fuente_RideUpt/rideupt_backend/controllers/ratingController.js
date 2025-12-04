// controllers/ratingController.js
const mongoose = require('mongoose');
const Rating = require('../models/Rating');
const User = require('../models/User');
const Trip = require('../models/Trip');

// Crear una nueva calificación
exports.createRating = async (req, res) => {
  try {
    const { ratedId, tripId, rating, comment, ratingType } = req.body;
    const raterId = req.user._id;

    // Validaciones
    if (!ratedId || !tripId || !rating || !ratingType) {
      return res.status(400).json({
        success: false,
        message: 'Faltan campos requeridos'
      });
    }

    if (rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'La calificación debe estar entre 1 y 5'
      });
    }

    if (!['driver', 'passenger'].includes(ratingType)) {
      return res.status(400).json({
        success: false,
        message: 'Tipo de calificación inválido'
      });
    }

    // Verificar que el viaje existe y está completado
    const trip = await Trip.findById(tripId);
    if (!trip) {
      return res.status(404).json({
        success: false,
        message: 'Viaje no encontrado'
      });
    }

    if (trip.status !== 'completado') {
      return res.status(400).json({
        success: false,
        message: `Solo se pueden calificar viajes completados. El estado actual del viaje es: ${trip.status}`
      });
    }

    // Verificar que el usuario calificado existe
    const ratedUser = await User.findById(ratedId);
    if (!ratedUser) {
      return res.status(404).json({
        success: false,
        message: 'Usuario a calificar no encontrado'
      });
    }

    // Verificar que no se puede calificar a sí mismo
    if (raterId === ratedId) {
      return res.status(400).json({
        success: false,
        message: 'No puedes calificarte a ti mismo'
      });
    }

    // Verificar que el usuario que califica participó en el viaje
    const isDriver = trip.driver.toString() === raterId.toString();
    const isPassenger = trip.passengers.some(p => {
      const passengerUserId = p.user.toString ? p.user.toString() : p.user;
      const raterIdStr = raterId.toString();
      return passengerUserId === raterIdStr && p.status === 'confirmed';
    });
    const isParticipant = isDriver || isPassenger;
    
    if (!isParticipant) {
      return res.status(400).json({
        success: false,
        message: 'Solo los participantes confirmados del viaje pueden calificar'
      });
    }
    
    // Verificar que el usuario calificado también participó en el viaje
    const isRatedDriver = trip.driver.toString() === ratedId.toString();
    const isRatedPassenger = trip.passengers.some(p => {
      const passengerUserId = p.user.toString ? p.user.toString() : p.user;
      const ratedIdStr = ratedId.toString();
      return passengerUserId === ratedIdStr && p.status === 'confirmed';
    });
    const ratedParticipated = isRatedDriver || isRatedPassenger;
    
    if (!ratedParticipated) {
      return res.status(400).json({
        success: false,
        message: 'El usuario calificado no participó en este viaje'
      });
    }

    // Verificar que no se haya calificado antes
    const existingRating = await Rating.findOne({
      rater: raterId,
      rated: ratedId,
      trip: tripId,
      ratingType: ratingType
    });

    if (existingRating) {
      return res.status(400).json({
        success: false,
        message: 'Ya has calificado a este usuario para este viaje'
      });
    }

    // Crear la calificación
    const newRating = new Rating({
      rater: raterId,
      rated: ratedId,
      trip: tripId,
      rating: rating,
      comment: comment || null,
      ratingType: ratingType
    });

    await newRating.save();

    // Poblar datos del usuario que califica
    await newRating.populate('rater', 'firstName lastName profilePhoto');

    res.status(201).json({
      success: true,
      message: 'Calificación creada exitosamente',
      data: newRating
    });

  } catch (error) {
    console.error('Error creando calificación:', error);
    console.error('Stack trace:', error.stack);
    res.status(500).json({
      success: false,
      message: `Error al crear calificación: ${error.message}`
    });
  }
};

// Obtener calificaciones de un usuario
exports.getUserRatings = async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 10, ratingType } = req.query;

    const query = { rated: userId };
    if (ratingType) {
      query.ratingType = ratingType;
    }

    const ratings = await Rating.find(query)
      .populate('rater', 'firstName lastName profilePhoto')
      .populate('trip', 'origin destination departureTime')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Rating.countDocuments(query);

    res.json({
      success: true,
      data: {
        ratings,
        pagination: {
          current: page,
          pages: Math.ceil(total / limit),
          total
        }
      }
    });

  } catch (error) {
    console.error('Error obteniendo calificaciones:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};

// Obtener estadísticas de calificaciones de un usuario
exports.getUserRatingStats = async (req, res) => {
  try {
    const { userId } = req.params;

    const stats = await Rating.aggregate([
      { $match: { rated: new mongoose.Types.ObjectId(userId) } },
      {
        $group: {
          _id: '$ratingType',
          averageRating: { $avg: '$rating' },
          totalRatings: { $sum: 1 },
          ratingDistribution: {
            $push: {
              rating: '$rating',
              comment: '$comment',
              createdAt: '$createdAt'
            }
          }
        }
      }
    ]);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('Error obteniendo estadísticas:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};

// Obtener calificaciones que el usuario ha dado
exports.getRatingsGiven = async (req, res) => {
  try {
    const raterId = req.user._id;
    const { page = 1, limit = 10 } = req.query;

    const ratings = await Rating.find({ rater: raterId })
      .populate('rated', 'firstName lastName profilePhoto')
      .populate('trip', 'origin destination departureTime')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Rating.countDocuments({ rater: raterId });

    res.json({
      success: true,
      data: {
        ratings,
        pagination: {
          current: page,
          pages: Math.ceil(total / limit),
          total
        }
      }
    });

  } catch (error) {
    console.error('Error obteniendo calificaciones dadas:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};

// Verificar si se puede calificar a un usuario en un viaje específico
exports.canRateUser = async (req, res) => {
  try {
    const { ratedId, tripId, ratingType } = req.params;
    const raterId = req.user._id;

    // Verificar si ya se calificó
    const existingRating = await Rating.findOne({
      rater: raterId,
      rated: ratedId,
      trip: tripId,
      ratingType: ratingType
    });

    // Verificar que el viaje está completado
    const trip = await Trip.findById(tripId);
    const canRate = trip && trip.status === 'completado' && !existingRating;

    res.json({
      success: true,
      data: {
        canRate,
        alreadyRated: !!existingRating,
        tripStatus: trip?.status
      }
    });

  } catch (error) {
    console.error('Error verificando si se puede calificar:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};

// Endpoint de prueba para verificar el sistema de calificaciones
exports.testRatingSystem = async (req, res) => {
  try {
    const timestamp = new Date().toISOString();
    console.log(`🧪 [${timestamp}] Probando sistema de calificaciones`);
    
    // Obtener estadísticas generales
    const totalRatings = await Rating.countDocuments();
    const driverRatings = await Rating.countDocuments({ ratingType: 'driver' });
    const passengerRatings = await Rating.countDocuments({ ratingType: 'passenger' });
    
    // Obtener promedio general
    const avgResult = await Rating.aggregate([
      { $group: { _id: null, averageRating: { $avg: '$rating' } } }
    ]);
    
    const averageRating = avgResult.length > 0 ? avgResult[0].averageRating : 0;
    
    res.json({
      success: true,
      message: 'Sistema de calificaciones funcionando correctamente',
      data: {
        totalRatings,
        driverRatings,
        passengerRatings,
        averageRating: Math.round(averageRating * 10) / 10,
        timestamp
      }
    });
    
  } catch (error) {
    console.error('Error probando sistema de calificaciones:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};