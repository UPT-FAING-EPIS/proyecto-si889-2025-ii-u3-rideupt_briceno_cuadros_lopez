// controllers/adminController.js
const User = require('../models/User');
const Rating = require('../models/Rating');
const { sendPushNotification } = require('../services/notificationService');
const { getDocumentUrl } = require('../config/storage');

/**
 * Verificar si el usuario es administrador
 */
const isAdmin = (req, res, next) => {
  if (req.user && req.user.isAdmin === true) {
    next();
  } else {
    res.status(403).json({ message: 'Acceso denegado. Se requieren permisos de administrador.' });
  }
};

/**
 * Obtener todos los conductores pendientes de aprobación
 */
exports.getPendingDrivers = async (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`👮 [${timestamp}] Obteniendo conductores pendientes - Admin: ${req.user._id}`);
  
  try {
    // Buscar usuarios con solicitud de conductor pendiente
    // Incluye usuarios que tengan documentos o vehículo, incluso si role aún no es 'driver'
    const pendingDrivers = await User.find({
      driverApprovalStatus: 'pending',
      $or: [
        { role: 'driver' },
        { driverDocuments: { $exists: true, $ne: [] } },
        { vehicle: { $exists: true, $ne: null } }
      ]
    })
    .select('firstName lastName email phone university studentId vehicle driverDocuments driverApprovalStatus createdAt')
    .sort({ createdAt: -1 });

    console.log(`✅ [${timestamp}] Encontrados ${pendingDrivers.length} conductores pendientes`);
    
    // Convertir URLs relativas de documentos a URLs absolutas
    const driversWithAbsoluteUrls = pendingDrivers.map(driver => {
      const driverObj = driver.toObject();
      if (driverObj.driverDocuments && Array.isArray(driverObj.driverDocuments)) {
        driverObj.driverDocuments = driverObj.driverDocuments.map(doc => {
          if (doc.urlImagen && !doc.urlImagen.startsWith('http')) {
            // Extraer el nombre del archivo de la URL relativa
            const filename = doc.urlImagen.split('/').pop();
            doc.urlImagen = getDocumentUrl(filename, req);
          }
          return doc;
        });
      }
      return driverObj;
    });
    
    res.json({
      count: driversWithAbsoluteUrls.length,
      drivers: driversWithAbsoluteUrls
    });
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al obtener conductores pendientes: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

/**
 * Obtener todos los conductores (pendientes, aprobados y rechazados)
 */
exports.getAllDrivers = async (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`👮 [${timestamp}] Obteniendo todos los conductores - Admin: ${req.user._id}`);
  
  try {
    const { status } = req.query; // Opcional: 'pending', 'approved', 'rejected'
    
    // Buscar usuarios que sean conductores O que tengan documentos/vehículo (solicitud de conductor)
    const query = {
      $or: [
        { role: 'driver' },
        { driverDocuments: { $exists: true, $ne: [] } },
        { vehicle: { $exists: true, $ne: null } },
        { driverApprovalStatus: { $exists: true, $ne: null } }
      ]
    };
    
    if (status) {
      query.driverApprovalStatus = status;
    }
    
    const drivers = await User.find(query)
      .select('firstName lastName email phone university studentId vehicle driverDocuments driverApprovalStatus driverRejectionReason createdAt')
      .sort({ createdAt: -1 });

    console.log(`✅ [${timestamp}] Encontrados ${drivers.length} conductores`);
    
    // Convertir URLs relativas de documentos a URLs absolutas
    const driversWithAbsoluteUrls = drivers.map(driver => {
      const driverObj = driver.toObject();
      if (driverObj.driverDocuments && Array.isArray(driverObj.driverDocuments)) {
        driverObj.driverDocuments = driverObj.driverDocuments.map(doc => {
          if (doc.urlImagen && !doc.urlImagen.startsWith('http')) {
            // Extraer el nombre del archivo de la URL relativa
            const filename = doc.urlImagen.split('/').pop();
            doc.urlImagen = getDocumentUrl(filename, req);
          }
          return doc;
        });
      }
      return driverObj;
    });
    
    res.json({
      count: driversWithAbsoluteUrls.length,
      drivers: driversWithAbsoluteUrls
    });
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al obtener conductores: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

/**
 * Aprobar un conductor
 */
exports.approveDriver = async (req, res) => {
  const timestamp = new Date().toISOString();
  const { driverId } = req.params;
  
  console.log(`👮 [${timestamp}] Aprobando conductor - ID: ${driverId}, Admin: ${req.user._id}`);
  
  try {
    const driver = await User.findById(driverId);
    
    if (!driver) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }
    
    // Verificar que tenga todos los documentos requeridos
    const requiredDocs = ['Foto del Vehículo', 'Tarjeta de Propiedad', 'Carnet Universitario'];
    const hasAllDocs = requiredDocs.every(docType => 
      driver.driverDocuments && driver.driverDocuments.some(doc => doc.tipoDocumento === docType)
    );
    
    if (!hasAllDocs) {
      return res.status(400).json({ 
        message: 'El conductor no ha subido todos los documentos requeridos' 
      });
    }
    
    // Verificar que tenga vehículo registrado
    if (!driver.vehicle) {
      return res.status(400).json({ 
        message: 'El conductor no tiene vehículo registrado' 
      });
    }
    
    // Establecer role como 'driver' si aún no lo es
    if (driver.role !== 'driver') {
      driver.role = 'driver';
      console.log(`   🔄 [${timestamp}] Role actualizado a 'driver'`);
    }
    
    driver.driverApprovalStatus = 'approved';
    driver.driverRejectionReason = null; // Limpiar razón de rechazo si existe
    driver.isDriverProfileComplete = true; // Asegurar que el perfil esté completo
    await driver.save();
    
    console.log(`✅ [${timestamp}] Conductor aprobado exitosamente`);
    console.log(`   👤 Conductor: ${driver.firstName} ${driver.lastName}`);
    console.log(`   📧 Email: ${driver.email}`);
    
    // Enviar notificación push al conductor
    try {
      await sendPushNotification(
        driver._id.toString(),
        '¡Solicitud Aprobada!',
        `¡Felicitaciones ${driver.firstName}! Tu solicitud para ser conductor ha sido aprobada. Ya puedes crear viajes.`,
        {
          type: 'DRIVER_APPROVED',
          driverId: driver._id.toString()
        }
      );
      console.log(`   📱 Notificación enviada al conductor`);
    } catch (notificationError) {
      console.error(`   ⚠️  Error enviando notificación: ${notificationError.message}`);
      // No fallar la aprobación si la notificación falla
    }
    
    res.json({
      message: 'Conductor aprobado exitosamente',
      driver: {
        _id: driver._id,
        firstName: driver.firstName,
        lastName: driver.lastName,
        email: driver.email,
        driverApprovalStatus: driver.driverApprovalStatus
      }
    });
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al aprobar conductor: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

/**
 * Rechazar un conductor
 */
exports.rejectDriver = async (req, res) => {
  const timestamp = new Date().toISOString();
  const { driverId } = req.params;
  const { reason } = req.body;
  
  console.log(`👮 [${timestamp}] Rechazando conductor - ID: ${driverId}, Admin: ${req.user._id}`);
  
  try {
    const driver = await User.findById(driverId);
    
    if (!driver) {
      return res.status(404).json({ message: 'Conductor no encontrado' });
    }
    
    if (driver.role !== 'driver') {
      return res.status(400).json({ message: 'El usuario no es un conductor' });
    }
    
    driver.driverApprovalStatus = 'rejected';
    driver.driverRejectionReason = reason || 'Documentos no cumplen con los requisitos';
    await driver.save();
    
    console.log(`✅ [${timestamp}] Conductor rechazado`);
    console.log(`   👤 Conductor: ${driver.firstName} ${driver.lastName}`);
    console.log(`   📧 Email: ${driver.email}`);
    console.log(`   📝 Razón: ${driver.driverRejectionReason}`);
    
    // Enviar notificación push al conductor
    try {
      const rejectionMessage = reason 
        ? `Tu solicitud fue rechazada. Razón: ${reason}. Puedes corregir tus documentos y volver a enviar tu solicitud.`
        : 'Tu solicitud fue rechazada. Puedes corregir tus documentos y volver a enviar tu solicitud desde tu perfil.';
      
      await sendPushNotification(
        driver._id.toString(),
        'Solicitud Rechazada',
        rejectionMessage,
        {
          type: 'DRIVER_REJECTED',
          driverId: driver._id.toString(),
          rejectionReason: driver.driverRejectionReason
        }
      );
      console.log(`   📱 Notificación enviada al conductor`);
    } catch (notificationError) {
      console.error(`   ⚠️  Error enviando notificación: ${notificationError.message}`);
      // No fallar el rechazo si la notificación falla
    }
    
    res.json({
      message: 'Conductor rechazado exitosamente',
      driver: {
        _id: driver._id,
        firstName: driver.firstName,
        lastName: driver.lastName,
        email: driver.email,
        driverApprovalStatus: driver.driverApprovalStatus,
        driverRejectionReason: driver.driverRejectionReason
      }
    });
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al rechazar conductor: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

/**
 * Obtener detalles de un conductor específico
 */
exports.getDriverDetails = async (req, res) => {
  const timestamp = new Date().toISOString();
  const { driverId } = req.params;
  
  console.log(`👮 [${timestamp}] Obteniendo detalles del conductor - ID: ${driverId}`);
  
  try {
    const driver = await User.findById(driverId)
      .select('firstName lastName email phone university studentId age gender bio role vehicle driverDocuments driverApprovalStatus driverRejectionReason isDriverProfileComplete createdAt updatedAt');
    
    if (!driver) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }
    
    // Verificar si es un conductor o está en proceso de convertirse en conductor
    // Un usuario se considera conductor si:
    // 1. Tiene role = 'driver', O
    // 2. Tiene documentos de conductor, O
    // 3. Tiene vehículo registrado, O
    // 4. Tiene driverApprovalStatus establecido (pending, approved, rejected)
    const isDriver = driver.role === 'driver' || 
                     (driver.driverDocuments && driver.driverDocuments.length > 0) ||
                     driver.vehicle ||
                     driver.driverApprovalStatus;
    
    if (!isDriver) {
      return res.status(400).json({ 
        message: 'Este usuario no es un conductor ni tiene solicitud de conductor pendiente' 
      });
    }
    
    console.log(`✅ [${timestamp}] Detalles del conductor obtenidos`);
    console.log(`   👤 Nombre: ${driver.firstName} ${driver.lastName}`);
    console.log(`   🎭 Rol: ${driver.role}`);
    console.log(`   📋 Estado: ${driver.driverApprovalStatus || 'N/A'}`);
    console.log(`   📄 Documentos: ${driver.driverDocuments?.length || 0}`);
    console.log(`   🚗 Vehículo: ${driver.vehicle ? 'Sí' : 'No'}`);
    
    // Convertir URLs relativas de documentos a URLs absolutas
    const driverObj = driver.toObject();
    if (driverObj.driverDocuments && Array.isArray(driverObj.driverDocuments)) {
      driverObj.driverDocuments = driverObj.driverDocuments.map(doc => {
        if (doc.urlImagen) {
          // Si ya es una URL absoluta, mantenerla
          if (doc.urlImagen.startsWith('http://') || doc.urlImagen.startsWith('https://')) {
            console.log(`   📷 URL absoluta encontrada: ${doc.urlImagen}`);
            return doc;
          }
          
          // Extraer el nombre del archivo de la URL relativa
          const filename = doc.urlImagen.split('/').pop();
          const absoluteUrl = getDocumentUrl(filename, req);
          console.log(`   📷 URL convertida: ${doc.urlImagen} -> ${absoluteUrl}`);
          doc.urlImagen = absoluteUrl;
        }
        return doc;
      });
    }
    
    res.json({
      driver: driverObj
    });
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al obtener detalles del conductor: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

/**
 * Obtener todos los usuarios (para administradores)
 */
exports.getAllUsers = async (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`👮 [${timestamp}] Obteniendo todos los usuarios - Admin: ${req.user._id}`);
  
  try {
    const { role, search } = req.query;
    
    const query = {};
    if (role) {
      query.role = role;
    }
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { studentId: { $regex: search, $options: 'i' } }
      ];
    }
    
    const users = await User.find(query)
      .select('firstName lastName email phone university studentId role isAdmin averageRating totalRatings driverApprovalStatus profilePhoto createdAt')
      .sort({ createdAt: -1 });

    console.log(`✅ [${timestamp}] Encontrados ${users.length} usuarios`);
    
    res.json({
      count: users.length,
      users: users
    });
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al obtener usuarios: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

/**
 * Obtener rankings de usuarios (conductores y pasajeros)
 */
exports.getUserRankings = async (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`👮 [${timestamp}] Obteniendo rankings de usuarios - Admin: ${req.user._id}`);
  
  try {
    const { type = 'all', limit = 50 } = req.query; // type: 'drivers', 'passengers', 'all'
    
    // Construir query base para usuarios
    const userQuery = {};
    if (type === 'drivers') {
      userQuery.role = 'driver';
      userQuery.driverApprovalStatus = 'approved';
    } else if (type === 'passengers') {
      userQuery.role = 'passenger';
    }
    
    // Obtener usuarios
    const users = await User.find(userQuery)
      .select('firstName lastName email role profilePhoto driverApprovalStatus _id')
      .limit(parseInt(limit) * 2); // Obtener más para filtrar después
    
    // Calcular calificaciones para cada usuario según su rol
    const rankingsWithRatings = await Promise.all(
      users.map(async (user) => {
        const ratingType = user.role === 'driver' ? 'driver' : 'passenger';
        
        // Calcular calificaciones dinámicamente según el rol
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

        let averageRating = 0;
        let totalRatings = 0;
        
        if (ratingStats.length > 0 && ratingStats[0].totalRatings > 0) {
          averageRating = Math.round(ratingStats[0].averageRating * 10) / 10;
          totalRatings = ratingStats[0].totalRatings;
        }

        return {
          user: user,
          averageRating: averageRating,
          totalRatings: totalRatings
        };
      })
    );

    // Filtrar usuarios con calificaciones y ordenar
    const filteredRankings = rankingsWithRatings
      .filter(item => item.totalRatings > 0)
      .sort((a, b) => {
        // Ordenar por promedio primero, luego por cantidad de calificaciones
        if (b.averageRating !== a.averageRating) {
          return b.averageRating - a.averageRating;
        }
        return b.totalRatings - a.totalRatings;
      })
      .slice(0, parseInt(limit)); // Limitar resultados

    console.log(`✅ [${timestamp}] Encontrados ${filteredRankings.length} usuarios en ranking`);
    
    res.json({
      count: filteredRankings.length,
      rankings: filteredRankings.map((item, index) => ({
        rank: index + 1,
        _id: item.user._id,
        firstName: item.user.firstName,
        lastName: item.user.lastName,
        email: item.user.email,
        role: item.user.role,
        averageRating: item.averageRating,
        totalRatings: item.totalRatings,
        profilePhoto: item.user.profilePhoto,
        driverApprovalStatus: item.user.driverApprovalStatus
      }))
    });
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al obtener rankings: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

/**
 * Obtener estadísticas generales del sistema
 */
exports.getSystemStats = async (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`👮 [${timestamp}] Obteniendo estadísticas del sistema - Admin: ${req.user._id}`);
  
  try {
    const Trip = require('../models/Trip');
    const Rating = require('../models/Rating');
    
    const [
      totalUsers,
      totalDrivers,
      totalPassengers,
      pendingDrivers,
      approvedDrivers,
      rejectedDrivers,
      totalTrips,
      completedTrips,
      totalRatings,
      averageRating
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ role: 'driver' }),
      User.countDocuments({ role: 'passenger' }),
      User.countDocuments({ role: 'driver', driverApprovalStatus: 'pending' }),
      User.countDocuments({ role: 'driver', driverApprovalStatus: 'approved' }),
      User.countDocuments({ role: 'driver', driverApprovalStatus: 'rejected' }),
      Trip.countDocuments(),
      Trip.countDocuments({ status: 'completado' }),
      Rating.countDocuments(),
      Rating.aggregate([
        { $group: { _id: null, averageRating: { $avg: '$rating' } } }
      ])
    ]);
    
    const avgRating = averageRating.length > 0 ? averageRating[0].averageRating : 0;
    
    res.json({
      users: {
        total: totalUsers,
        drivers: totalDrivers,
        passengers: totalPassengers
      },
      drivers: {
        pending: pendingDrivers,
        approved: approvedDrivers,
        rejected: rejectedDrivers
      },
      trips: {
        total: totalTrips,
        completed: completedTrips
      },
      ratings: {
        total: totalRatings,
        average: Math.round(avgRating * 10) / 10
      }
    });
  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al obtener estadísticas: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

module.exports.isAdmin = isAdmin;



