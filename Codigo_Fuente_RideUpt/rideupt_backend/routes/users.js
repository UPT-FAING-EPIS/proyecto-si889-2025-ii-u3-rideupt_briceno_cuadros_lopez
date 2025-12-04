// routes/users.js
const express = require('express');
const router = express.Router();
const { check } = require('express-validator');
const { getUserProfile, updateUserProfile, updateDriverProfile, resubmitDriverApplication, switchUserMode } = require('../controllers/userController');
const { protect } = require('../middleware/auth');
const { updateUserFcmToken } = require('../controllers/userController');

router.route('/profile')
    .get(protect, getUserProfile)
    .put(protect, updateUserProfile);

router.put(
  '/driver-profile',
  protect,
  [
    check('make', 'La marca del vehículo es obligatoria').not().isEmpty(),
    check('model', 'El modelo del vehículo es obligatorio').not().isEmpty(),
    check('year', 'El año del vehículo es obligatorio').isNumeric(),
    check('color', 'El color del vehículo es obligatorio').not().isEmpty(),
    check('licensePlate', 'La placa del vehículo es obligatoria').not().isEmpty(),
  ],
  updateDriverProfile
);

router.put('/fcm-token', protect, updateUserFcmToken);

// Endpoint para reenviar solicitud de conductor (cuando fue rechazada)
router.post('/resubmit-driver-application', protect, resubmitDriverApplication);

// Endpoint para cambiar modo del usuario
router.put('/switch-mode', protect, switchUserMode);

module.exports = router;