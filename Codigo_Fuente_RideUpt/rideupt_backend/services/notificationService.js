// services/notificationService.js
const admin = require('firebase-admin');
const User = require('../models/User');

const initializeFCM = () => {
  const serviceAccount = require('../config/firebase-service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('Firebase Admin SDK inicializado.');
};

const sendPushNotification = async (userId, title, body, data = {}) => {
  try {
    // Validar que userId sea un string válido y no un objeto
    if (!userId || typeof userId !== 'string') {
      // Si es un objeto, intentar extraer el _id
      if (userId && typeof userId === 'object') {
        userId = userId._id ? userId._id.toString() : userId.toString();
      } else {
        console.error(`Error: userId inválido para notificación push: ${typeof userId}`, userId);
        return;
      }
    }
    
    // Asegurar que userId sea un string válido de ObjectId (24 caracteres hex)
    if (userId.length !== 24 || !/^[0-9a-fA-F]{24}$/.test(userId)) {
      console.error(`Error: userId no es un ObjectId válido: ${userId}`);
      return;
    }
    
    const user = await User.findById(userId);
    if (!user || !user.fcmToken) {
      console.log(`Usuario ${userId} no encontrado o sin token FCM.`);
      return;
    }

    const message = {
      notification: { title, body },
      data: data,
      token: user.fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log('Notificación enviada exitosamente:', response);
  } catch (error) {
    console.error('Error enviando notificación push:', error);
  }
};

module.exports = { initializeFCM, sendPushNotification };