// routes/ratings.js
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  createRating,
  getUserRatings,
  getUserRatingStats,
  getRatingsGiven,
  canRateUser,
  testRatingSystem
} = require('../controllers/ratingController');

// Crear una nueva calificación
router.post('/', protect, createRating);

// Obtener calificaciones de un usuario específico
router.get('/user/:userId', protect, getUserRatings);

// Obtener estadísticas de calificaciones de un usuario
router.get('/user/:userId/stats', protect, getUserRatingStats);

// Obtener calificaciones que el usuario autenticado ha dado
router.get('/given', protect, getRatingsGiven);

// Verificar si se puede calificar a un usuario en un viaje específico
router.get('/can-rate/:ratedId/:tripId/:ratingType', protect, canRateUser);

// Endpoint de prueba para verificar el sistema
router.get('/test', testRatingSystem);

module.exports = router;