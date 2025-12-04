// routes/dashboard.js
const express = require('express');
const router = express.Router();
const { getDashboardStats, getRecentTrips } = require('../controllers/dashboardController');
const { protect } = require('../middleware/auth');

// Obtener estadísticas del dashboard
router.get('/stats', protect, getDashboardStats);

// Obtener viajes recientes
router.get('/recent-trips', protect, getRecentTrips);

module.exports = router;



