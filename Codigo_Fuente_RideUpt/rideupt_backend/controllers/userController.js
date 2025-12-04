// controllers/userController.js
const User = require('../models/User');
const Trip = require('../models/Trip');
const Rating = require('../models/Rating');
const { validationResult } = require('express-validator');

// Función auxiliar para actualizar calificaciones según el rol del usuario
async function updateUserRatings(userId, role) {
  try {
    const ratingType = role === 'driver' ? 'driver' : 'passenger';
    
    const ratingStats = await Rating.aggregate([
      { 
        $match: { 
          rated: userId,
          ratingType: ratingType
        } 
      },
      {
        $group: {
          _id: null,
          averageRating: { $avg: '$rating' },
          totalRatings: { $sum: 1 }
        }
      }
    ]);

    if (ratingStats.length > 0) {
      const averageRating = Math.round(ratingStats[0].averageRating * 10) / 10;
      const totalRatings = ratingStats[0].totalRatings;
      
      await User.findByIdAndUpdate(userId, {
        averageRating: averageRating,
        totalRatings: totalRatings
      });
      
      return { averageRating, totalRatings };
    } else {
      await User.findByIdAndUpdate(userId, {
        averageRating: 0,
        totalRatings: 0
      });
      
      return { averageRating: 0, totalRatings: 0 };
    }
  } catch (error) {
    console.error('Error actualizando calificaciones del usuario:', error);
    return null;
  }
}

// Obtener perfil del usuario logueado
exports.getUserProfile = async (req, res) => {
  const timestamp = new Date().toISOString();
  try {
    // req.user es adjuntado por el middleware 'protect'
    const user = await User.findById(req.user._id).select('-password');
    if (user) {
      // Calcular calificaciones según el rol ACTUAL del usuario
      // Si es conductor, mostrar calificaciones como conductor
      // Si es pasajero, mostrar calificaciones como pasajero
      const ratingType = user.role === 'driver' ? 'driver' : 'passenger';
      
      const ratingStats = await Rating.aggregate([
        { 
          $match: { 
            rated: user._id,
            ratingType: ratingType
          } 
        },
        {
          $group: {
            _id: null,
            averageRating: { $avg: '$rating' },
            totalRatings: { $sum: 1 }
          }
        }
      ]);

      // Actualizar las calificaciones en el objeto usuario
      if (ratingStats.length > 0) {
        user.averageRating = Math.round(ratingStats[0].averageRating * 10) / 10;
        user.totalRatings = ratingStats[0].totalRatings;
      } else {
        // Si no hay calificaciones del tipo actual, establecer en 0
        user.averageRating = 0;
        user.totalRatings = 0;
      }

      // SIEMPRE guardar las calificaciones actualizadas en la base de datos
      // Esto asegura que las calificaciones se actualicen cuando el usuario cambia de rol
      await User.findByIdAndUpdate(user._id, {
        averageRating: user.averageRating,
        totalRatings: user.totalRatings
      }, { new: true });

      console.log(`✅ [${timestamp}] Perfil obtenido - Usuario: ${user.email}`);
      console.log(`   📷 Foto: ${user.profilePhoto || 'default_avatar.png'}`);
      console.log(`   ⭐ Calificaciones (${ratingType}): ${user.averageRating} (${user.totalRatings} calificaciones)`);
      
      res.json(user);
    } else {
      console.error(`❌ [${timestamp}] Usuario no encontrado: ${req.user._id}`);
      res.status(404).json({ message: 'Usuario no encontrado' });
    }
  } catch (error) {
    console.error(`❌ [${timestamp}] Error al obtener perfil: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

// Actualizar perfil del usuario (nombre, teléfono, edad, sexo, bio, etc.)
exports.updateUserProfile = async (req, res) => {
    const timestamp = new Date().toISOString();
    console.log(`📝 [${timestamp}] Actualizando perfil - Usuario: ${req.user._id}`);
    
    try {
        const user = await User.findById(req.user._id);

        if (user) {
            // Actualizar campos básicos
            user.firstName = req.body.firstName || user.firstName;
            user.lastName = req.body.lastName || user.lastName;
            user.phone = req.body.phone || user.phone;
            
            // Actualizar nuevos campos (opcionales)
            if (req.body.age !== undefined) {
                user.age = req.body.age;
            }
            if (req.body.gender !== undefined) {
                user.gender = req.body.gender;
            }
            if (req.body.bio !== undefined) {
                user.bio = req.body.bio;
            }
            
            // No permitir cambiar email, studentId, university o profilePhoto
            // profilePhoto viene de Google y no se puede cambiar desde aquí

            const updatedUser = await user.save();
            
            console.log(`✅ [${timestamp}] Perfil actualizado exitosamente`);
            console.log(`   👤 Nombre: ${updatedUser.firstName} ${updatedUser.lastName}`);
            console.log(`   📞 Teléfono: ${updatedUser.phone}`);
            console.log(`   🎂 Edad: ${updatedUser.age || 'No especificada'}`);
            console.log(`   👥 Sexo: ${updatedUser.gender || 'No especificado'}`);
            console.log(`   📷 Foto: ${updatedUser.profilePhoto || 'default_avatar.png'}`);
            
            res.json({
                _id: updatedUser._id,
                firstName: updatedUser.firstName,
                lastName: updatedUser.lastName,
                email: updatedUser.email,
                phone: updatedUser.phone,
                age: updatedUser.age,
                gender: updatedUser.gender,
                bio: updatedUser.bio,
                role: updatedUser.role,
                university: updatedUser.university,
                studentId: updatedUser.studentId,
                profilePhoto: updatedUser.profilePhoto,
            });
        } else {
            console.error(`❌ [${timestamp}] Usuario no encontrado: ${req.user._id}`);
            res.status(404).json({ message: 'Usuario no encontrado' });
        }
    } catch (error) {
        console.error('═══════════════════════════════════════════════════════');
        console.error(`🔴 ERROR AL ACTUALIZAR PERFIL [${timestamp}]`);
        console.error(`📝 Mensaje: ${error.message}`);
        console.error(`📋 Stack: ${error.stack}`);
        console.error('═══════════════════════════════════════════════════════');
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};

// Actualizar/Crear perfil de conductor (datos del vehículo)
exports.updateDriverProfile = async (req, res) => {
  const timestamp = new Date().toISOString();
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { make, model, year, color, licensePlate, totalSeats } = req.body;

  console.log(`🚗 [${timestamp}] Actualizando perfil de conductor - Usuario: ${req.user._id}`);

  try {
    const user = await User.findById(req.user._id);

    if (user) {
      user.vehicle = { 
        make, 
        model, 
        year, 
        color, 
        licensePlate,
        totalSeats: totalSeats || 4, // Por defecto 4 asientos
      };
      user.role = 'driver'; // Ascender a rol de conductor
      user.isDriverProfileComplete = true; // Marcar perfil como completo
      user.driverApprovalStatus = 'pending'; // Estado pendiente hasta aprobación del admin

      const updatedUser = await user.save();
      
      // Actualizar calificaciones como conductor
      await updateUserRatings(user._id, 'driver');
      
      console.log(`✅ [${timestamp}] Perfil de conductor actualizado`);
      console.log(`   🚗 Vehículo: ${make} ${model}`);
      console.log(`   🪑 Asientos: ${totalSeats || 4}`);
      console.log(`   🚘 Placa: ${licensePlate}`);
      
      res.json(updatedUser.vehicle);
    } else {
      res.status(404).json({ message: 'Usuario no encontrado' });
    }
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al actualizar perfil de conductor: ${error.message}`);
    // Manejar error de placa duplicada
    if (error.code === 11000) {
        return res.status(400).json({ message: 'La placa del vehículo ya está registrada.' });
    }
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

exports.updateUserFcmToken = async (req, res) => {
    const { fcmToken } = req.body;
    try {
        const user = await User.findById(req.user._id);
        if (user) {
            user.fcmToken = fcmToken;
            await user.save();
            res.json({ message: 'Token FCM actualizado' });
        } else {
            res.status(404).json({ message: 'Usuario no encontrado' });
        }
    } catch (error) {
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};

// Volver a enviar solicitud de conductor (cuando fue rechazada)
exports.resubmitDriverApplication = async (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`🔄 [${timestamp}] Reenviando solicitud de conductor - Usuario: ${req.user._id}`);

  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // Verificar que el usuario sea conductor y que su solicitud haya sido rechazada
    if (user.role !== 'driver') {
      return res.status(400).json({ message: 'Solo los conductores pueden reenviar su solicitud' });
    }

    if (user.driverApprovalStatus !== 'rejected') {
      return res.status(400).json({ 
        message: 'Solo puedes reenviar tu solicitud si fue rechazada previamente' 
      });
    }

    // Verificar que tenga todos los documentos requeridos
    const requiredDocs = ['Foto del Vehículo', 'Tarjeta de Propiedad', 'Carnet Universitario'];
    const hasAllDocs = requiredDocs.every(docType => 
      user.driverDocuments && user.driverDocuments.some(doc => doc.tipoDocumento === docType)
    );

    if (!hasAllDocs) {
      return res.status(400).json({ 
        message: 'Debes subir todos los documentos requeridos antes de reenviar tu solicitud' 
      });
    }

    // Verificar que tenga vehículo registrado
    if (!user.vehicle) {
      return res.status(400).json({ 
        message: 'Debes completar los datos de tu vehículo antes de reenviar tu solicitud' 
      });
    }

    // Resetear estado a pendiente y limpiar razón de rechazo
    user.driverApprovalStatus = 'pending';
    user.driverRejectionReason = null;
    await user.save();

    console.log(`✅ [${timestamp}] Solicitud reenviada exitosamente`);
    console.log(`   👤 Usuario: ${user.firstName} ${user.lastName}`);
    console.log(`   📧 Email: ${user.email}`);

    res.json({
      message: 'Solicitud reenviada exitosamente. Tu solicitud está pendiente de revisión.',
      driverApprovalStatus: user.driverApprovalStatus
    });
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al reenviar solicitud: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

// Cambiar modo del usuario (conductor/pasajero)
exports.switchUserMode = async (req, res) => {
    const timestamp = new Date().toISOString();
    const { mode } = req.body;
    
    console.log(`🔄 [${timestamp}] Cambiando modo de usuario - Usuario: ${req.user._id}, Modo: ${mode}`);
    
    try {
        const user = await User.findById(req.user._id);
        
        if (!user) {
            console.error(`❌ [${timestamp}] Usuario no encontrado: ${req.user._id}`);
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }
        
        // Validar que el modo sea válido
        if (!['driver', 'passenger'].includes(mode)) {
            console.error(`❌ [${timestamp}] Modo inválido: ${mode}`);
            return res.status(400).json({ message: 'Modo inválido. Debe ser "driver" o "passenger"' });
        }
        
        // Si está cambiando a conductor, verificar que tenga perfil completo
        if (mode === 'driver' && !user.isDriverProfileComplete) {
            console.error(`❌ [${timestamp}] Usuario intenta cambiar a conductor sin perfil completo`);
            return res.status(400).json({ 
                message: 'Debes completar tu perfil de conductor primero',
                requiresDriverProfile: true 
            });
        }
        
        // Si está cambiando a pasajero, verificar que no tenga viajes activos
        if (mode === 'passenger' && user.role === 'driver') {
            const now = new Date();
            
            // Buscar viajes activos: en proceso, esperando, completo (que no hayan expirado)
            const activeTrip = await Trip.findOne({
                driver: user._id,
                status: { $in: ['en-proceso', 'esperando', 'completo'] },
                $or: [
                    { expiresAt: { $gt: now } },
                    { expiresAt: null },
                    { status: 'en-proceso' } // Los viajes en proceso no expiran
                ]
            });
            
            if (activeTrip) {
                console.error(`❌ [${timestamp}] Usuario intenta cambiar a pasajero con viaje activo: ${activeTrip._id}`);
                return res.status(400).json({ 
                    message: 'No puedes cambiar a modo pasajero mientras tengas viajes activos o en proceso. Debes completar o cancelar todos tus viajes primero.',
                    hasActiveTrips: true
                });
            }
        }
        
        // Actualizar el rol
        const previousRole = user.role;
        user.role = mode;
        
        const updatedUser = await user.save();
        
        // Actualizar calificaciones según el nuevo rol
        const ratingStats = await updateUserRatings(user._id, mode);
        if (ratingStats) {
          updatedUser.averageRating = ratingStats.averageRating;
          updatedUser.totalRatings = ratingStats.totalRatings;
        }
        
        console.log(`✅ [${timestamp}] Modo cambiado exitosamente`);
        console.log(`   🔄 De: ${previousRole} → A: ${mode}`);
        console.log(`   👤 Usuario: ${updatedUser.firstName} ${updatedUser.lastName}`);
        if (ratingStats) {
          console.log(`   ⭐ Calificaciones actualizadas: ${ratingStats.averageRating} (${ratingStats.totalRatings} calificaciones)`);
        }
        
        res.json({
            message: `Modo cambiado a ${mode === 'driver' ? 'conductor' : 'pasajero'}`,
            user: {
                _id: updatedUser._id,
                firstName: updatedUser.firstName,
                lastName: updatedUser.lastName,
                email: updatedUser.email,
                role: updatedUser.role,
                phone: updatedUser.phone,
                university: updatedUser.university,
                studentId: updatedUser.studentId,
                profilePhoto: updatedUser.profilePhoto,
                age: updatedUser.age,
                gender: updatedUser.gender,
                bio: updatedUser.bio,
                vehicle: updatedUser.vehicle,
                averageRating: updatedUser.averageRating,
                totalRatings: updatedUser.totalRatings,
                isDriverProfileComplete: updatedUser.isDriverProfileComplete,
            }
        });
        
    } catch (error) {
        console.error('═══════════════════════════════════════════════════════');
        console.error(`🔴 ERROR AL CAMBIAR MODO [${timestamp}]`);
        console.error(`📝 Mensaje: ${error.message}`);
        console.error(`📋 Stack: ${error.stack}`);
        console.error('═══════════════════════════════════════════════════════');
        res.status(500).json({ message: `Error del servidor: ${error.message}` });
    }
};