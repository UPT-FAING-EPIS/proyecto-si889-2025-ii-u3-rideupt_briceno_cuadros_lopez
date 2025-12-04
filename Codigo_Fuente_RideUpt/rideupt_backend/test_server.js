// test_server.js - Script para probar que el servidor funcione
const express = require('express');
const mongoose = require('mongoose');

console.log('🧪 Probando configuración del servidor...');

// Probar conexión a MongoDB
mongoose.connect('mongodb://localhost:27017/rideupt', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log('✅ MongoDB connection successful');
  process.exit(0);
})
.catch(err => {
  console.error('❌ MongoDB connection failed:', err.message);
  console.log('💡 Asegúrate de que MongoDB esté ejecutándose en localhost:27017');
  process.exit(1);
});

