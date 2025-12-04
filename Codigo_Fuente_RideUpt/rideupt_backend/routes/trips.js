// routes/trips.js
const express = require('express');
const router = express.Router();
const { protect, isDriver } = require('../middleware/auth');
const { 
    createTrip,
    getAvailableTrips,
    getTripById,
    requestBooking,
    manageBooking,
    getMyDriverTrips,
    getMyPassengerTrips,
    startTrip,
    cancelTrip,
    leaveTrip,
    completeTrip,
    confirmInVehicle
} = require('../controllers/tripController');


// Rutas para todos los usuarios autenticados
router.route('/')
    .get(protect, getAvailableTrips)
    .post(protect, createTrip);

router.get('/my-passenger-trips', protect, getMyPassengerTrips);
router.post('/:id/book', protect, requestBooking);

// Rutas específicas para conductores
router.get('/my-driver-trips', protect, getMyDriverTrips);
router.put('/:tripId/bookings/:passengerId', protect, manageBooking);

// Nuevas rutas para gestión de viajes
router.put('/:id/start', protect, startTrip); // Iniciar viaje
router.put('/:id/complete', protect, completeTrip); // Finalizar viaje
router.put('/:id/cancel', protect, cancelTrip); // Cancelar viaje (conductor) - Cambiado a PUT para aceptar body
router.delete('/:id/leave', protect, leaveTrip); // Salir del viaje (pasajero)
router.put('/:id/confirm-in-vehicle', protect, confirmInVehicle); // Pasajero confirma que está en el vehículo

// Esta ruta debe ir al final para no interferir con las anteriores
router.route('/:id').get(protect, getTripById);


module.exports = router;