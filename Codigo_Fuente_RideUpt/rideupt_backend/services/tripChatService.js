// services/tripChatService.js
// Gestión de chat en memoria para viajes

// Estructura: tripChats[tripId] = {
//   messages: [array de mensajes],
//   participants: Set de userIds,
//   createdAt: Date,
//   isActive: boolean
// }
const tripChats = new Map();

/**
 * Inicializar el chat de un viaje cuando se crea
 * @param {string} tripId - ID del viaje
 * @param {string} driverId - ID del conductor
 */
const initializeTripChat = (tripId, driverId) => {
  if (!tripChats.has(tripId)) {
    tripChats.set(tripId, {
      messages: [],
      participants: new Set([driverId]),
      createdAt: new Date(),
      isActive: true
    });
    console.log(`✅ Chat inicializado para viaje ${tripId} - Conductor: ${driverId}`);
  }
};

/**
 * Agregar un mensaje al chat del viaje
 * @param {string} tripId - ID del viaje
 * @param {Object} message - Objeto del mensaje
 * @returns {Object|null} - El mensaje agregado o null si el chat no existe
 */
const addMessage = (tripId, message) => {
  const chat = tripChats.get(tripId);
  if (!chat || !chat.isActive) {
    return null;
  }

  chat.messages.push(message);
  console.log(`💬 Mensaje agregado al chat del viaje ${tripId} por ${message.userName}`);
  return message;
};

/**
 * Obtener el historial de mensajes de un viaje
 * @param {string} tripId - ID del viaje
 * @returns {Array} - Array de mensajes
 */
const getChatHistory = (tripId) => {
  const chat = tripChats.get(tripId);
  if (!chat || !chat.isActive) {
    return [];
  }
  return chat.messages;
};

/**
 * Agregar un participante al chat (conductor o pasajero aceptado)
 * @param {string} tripId - ID del viaje
 * @param {string} userId - ID del usuario
 */
const addParticipant = (tripId, userId) => {
  const chat = tripChats.get(tripId);
  if (!chat || !chat.isActive) {
    return false;
  }

  chat.participants.add(userId);
  console.log(`👤 Usuario ${userId} agregado al chat del viaje ${tripId}`);
  return true;
};

/**
 * Remover un participante del chat (cuando un pasajero abandona)
 * @param {string} tripId - ID del viaje
 * @param {string} userId - ID del usuario a remover
 */
const removeParticipant = (tripId, userId) => {
  const chat = tripChats.get(tripId);
  if (!chat) {
    return false;
  }

  chat.participants.delete(userId);
  console.log(`👋 Usuario ${userId} removido del chat del viaje ${tripId}`);
  return true;
};

/**
 * Verificar si un usuario es participante del chat
 * @param {string} tripId - ID del viaje
 * @param {string} userId - ID del usuario
 * @returns {boolean}
 */
const isParticipant = (tripId, userId) => {
  const chat = tripChats.get(tripId);
  if (!chat || !chat.isActive) {
    return false;
  }
  return chat.participants.has(userId);
};

/**
 * Cerrar el chat de un viaje (cuando se cancela, completa o termina)
 * @param {string} tripId - ID del viaje
 */
const closeTripChat = (tripId) => {
  const chat = tripChats.get(tripId);
  if (chat) {
    chat.isActive = false;
    console.log(`🔒 Chat del viaje ${tripId} cerrado`);
  }
};

/**
 * Eliminar completamente el chat de un viaje (limpieza)
 * @param {string} tripId - ID del viaje
 */
const deleteTripChat = (tripId) => {
  if (tripChats.has(tripId)) {
    tripChats.delete(tripId);
    console.log(`🗑️ Chat del viaje ${tripId} eliminado de memoria`);
  }
};

/**
 * Verificar si el chat está activo
 * @param {string} tripId - ID del viaje
 * @returns {boolean}
 */
const isChatActive = (tripId) => {
  const chat = tripChats.get(tripId);
  return chat ? chat.isActive : false;
};

/**
 * Obtener todos los participantes de un chat
 * @param {string} tripId - ID del viaje
 * @returns {Set} - Set de IDs de participantes
 */
const getParticipants = (tripId) => {
  const chat = tripChats.get(tripId);
  if (!chat || !chat.isActive) {
    return new Set();
  }
  return new Set(chat.participants);
};

module.exports = {
  initializeTripChat,
  addMessage,
  getChatHistory,
  addParticipant,
  removeParticipant,
  isParticipant,
  closeTripChat,
  deleteTripChat,
  isChatActive,
  getParticipants
};












