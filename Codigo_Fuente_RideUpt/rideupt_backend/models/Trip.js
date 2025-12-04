// models/Trip.js
const mongoose = require('mongoose');
const { Schema } = mongoose;

const pointSchema = new Schema({
  type: { type: String, enum: ['Point'], required: true },
  coordinates: { type: [Number], required: true }, // [longitud, latitud]
  name: { type: String, required: true } // Nombre del lugar (ej. "Centro Comercial X")
});

const passengerSchema = new Schema({
    user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    status: { type: String, enum: ['pending', 'confirmed', 'rejected', 'cancelled'], default: 'pending' },
    bookedAt: { type: Date, default: Date.now },
    inVehicle: { type: Boolean, default: false } // Indica si el pasajero ya está en el vehículo
});

const tripSchema = new Schema({
  driver: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  origin: { type: pointSchema, required: true },
  destination: { type: pointSchema, required: true },
  departureTime: { type: Date, required: true },
  expiresAt: { type: Date, required: true }, // Tiempo de expiración (6 minutos después de creación)
  availableSeats: { type: Number, required: true },
  seatsBooked: { type: Number, default: 0 },
  pricePerSeat: { type: Number, required: true },
  description: { type: String },
  status: { type: String, enum: ['esperando', 'completo', 'en-proceso', 'completado', 'expirado', 'cancelado'], default: 'esperando' },
  passengers: [passengerSchema],
}, {
  timestamps: true
});

tripSchema.index({ origin: '2dsphere', destination: '2dsphere' });

module.exports = mongoose.model('Trip', tripSchema);