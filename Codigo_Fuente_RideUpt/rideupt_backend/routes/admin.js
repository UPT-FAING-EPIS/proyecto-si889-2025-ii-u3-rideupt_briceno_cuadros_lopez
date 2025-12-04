// routes/admin.js
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { isAdmin } = require('../controllers/adminController');
const {
  getPendingDrivers,
  getAllDrivers,
  approveDriver,
  rejectDriver,
  getDriverDetails,
  getAllUsers,
  getUserRankings,
  getSystemStats
} = require('../controllers/adminController');

// Todas las rutas requieren autenticación y rol de administrador
router.use(protect);
router.use(isAdmin);

// Rutas del panel administrativo
router.get('/drivers/pending', getPendingDrivers);
router.get('/drivers', getAllDrivers);
router.get('/drivers/:driverId', getDriverDetails);
router.put('/drivers/:driverId/approve', approveDriver);
router.put('/drivers/:driverId/reject', rejectDriver);

// Rutas de usuarios
router.get('/users', getAllUsers);

// Rutas de rankings
router.get('/rankings', getUserRankings);

// Rutas de estadísticas
router.get('/stats', getSystemStats);

module.exports = router;




