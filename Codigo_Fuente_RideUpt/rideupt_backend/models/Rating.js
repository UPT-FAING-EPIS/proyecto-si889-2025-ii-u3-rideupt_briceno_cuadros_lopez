// models/Rating.js
const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema({
  // Usuario que da la calificación
  rater: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  // Usuario que recibe la calificación
  rated: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  // Viaje relacionado
  trip: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Trip',
    required: true
  },
  
  // Calificación (1-5)
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  
  // Comentario opcional
  comment: {
    type: String,
    maxlength: 500
  },
  
  // Tipo de calificación (driver o passenger)
  ratingType: {
    type: String,
    enum: ['driver', 'passenger'],
    required: true
  }
}, {
  timestamps: true
});

// Índices para optimizar consultas
ratingSchema.index({ rated: 1, ratingType: 1 });
ratingSchema.index({ rater: 1 });
ratingSchema.index({ trip: 1 });

// Middleware para actualizar estadísticas del usuario calificado
ratingSchema.post('save', async function() {
  try {
    const User = require('./User');
    const Rating = require('./Rating');
    
    // Obtener el usuario calificado para determinar su rol
    const ratedUser = await User.findById(this.rated);
    if (!ratedUser) return;
    
    // Calcular calificaciones según el tipo de calificación
    // Si es calificación como conductor, actualizar solo si el usuario es conductor
    // Si es calificación como pasajero, actualizar solo si el usuario es pasajero
    const ratingType = this.ratingType;
    
    // Obtener todas las calificaciones del mismo tipo para este usuario
    const ratings = await Rating.find({ 
      rated: this.rated,
      ratingType: ratingType 
    });
    
    if (ratings.length > 0) {
      // Calcular promedio
      const totalRating = ratings.reduce((sum, rating) => sum + rating.rating, 0);
      const averageRating = totalRating / ratings.length;
      
      // Actualizar estadísticas del usuario según el tipo de calificación
      // Si el tipo es 'driver', actualizar solo si el usuario es conductor
      // Si el tipo es 'passenger', actualizar solo si el usuario es pasajero
      // Esto asegura que las calificaciones se guarden correctamente según el rol
      if (ratingType === 'driver') {
        // Solo actualizar si el usuario es conductor
        if (ratedUser.role === 'driver') {
          await User.findByIdAndUpdate(this.rated, {
            averageRating: Math.round(averageRating * 10) / 10, // Redondear a 1 decimal
            totalRatings: ratings.length
          });
        }
      } else if (ratingType === 'passenger') {
        // Solo actualizar si el usuario es pasajero
        if (ratedUser.role === 'passenger') {
          await User.findByIdAndUpdate(this.rated, {
            averageRating: Math.round(averageRating * 10) / 10, // Redondear a 1 decimal
            totalRatings: ratings.length
          });
        }
      }
      
      // IMPORTANTE: Si el usuario cambia de rol, las calificaciones se actualizarán
      // cuando se llame a getUserProfile, que siempre recalcula según el rol actual
    }
  } catch (error) {
    console.error('Error actualizando estadísticas de calificación:', error);
  }
});

// Middleware para actualizar estadísticas cuando se elimina una calificación
ratingSchema.post('findOneAndRemove', async function() {
  try {
    const User = require('./User');
    const Rating = require('./Rating');
    
    if (this.result) {
      const deletedRating = this.result;
      const ratedUser = await User.findById(deletedRating.rated);
      if (!ratedUser) return;
      
      const ratingType = deletedRating.ratingType;
      
      // Recalcular calificaciones del mismo tipo
      const ratings = await Rating.find({ 
        rated: deletedRating.rated,
        ratingType: ratingType 
      });
      
      if (ratings.length > 0) {
        const totalRating = ratings.reduce((sum, rating) => sum + rating.rating, 0);
        const averageRating = totalRating / ratings.length;
        
        if (ratingType === 'driver' && ratedUser.role === 'driver') {
          await User.findByIdAndUpdate(deletedRating.rated, {
            averageRating: Math.round(averageRating * 10) / 10,
            totalRatings: ratings.length
          });
        } else if (ratingType === 'passenger' && ratedUser.role === 'passenger') {
          await User.findByIdAndUpdate(deletedRating.rated, {
            averageRating: Math.round(averageRating * 10) / 10,
            totalRatings: ratings.length
          });
        }
      } else {
        // Si no hay más calificaciones, resetear a 0
        if (ratingType === 'driver' && ratedUser.role === 'driver') {
          await User.findByIdAndUpdate(deletedRating.rated, {
            averageRating: 0,
            totalRatings: 0
          });
        } else if (ratingType === 'passenger' && ratedUser.role === 'passenger') {
          await User.findByIdAndUpdate(deletedRating.rated, {
            averageRating: 0,
            totalRatings: 0
          });
        }
      }
    }
  } catch (error) {
    console.error('Error actualizando estadísticas después de eliminar calificación:', error);
  }
});

module.exports = mongoose.model('Rating', ratingSchema);