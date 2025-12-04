// config/database.js
const mongoose = require('mongoose');

// Variable para rastrear intentos de reconexión
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 5;

const connectDB = async () => {
  const mongoUri = process.env.MONGO_URI;
  
  if (!mongoUri) {
    console.error('❌ ERROR CRÍTICO: MONGO_URI no está definida en las variables de entorno');
    console.log('💡 Verifica que el archivo .env existe y contiene:');
    console.log('   Para MongoDB Atlas: MONGO_URI=mongodb+srv://usuario:password@cluster.mongodb.net/rideupt');
    console.log('   Para MongoDB local: MONGO_URI=mongodb://localhost:27017/rideupt');
    process.exit(1);
  }

  // Ocultar password en logs (seguridad)
  const sanitizedUri = mongoUri.replace(/\/\/([^:]+):([^@]+)@/, '//***:***@');
  console.log(`🔄 Intentando conectar a MongoDB: ${sanitizedUri}`);
  console.log(`📅 Fecha/Hora: ${new Date().toISOString()}`);

  // Opciones optimizadas para MongoDB Atlas y producción
  const options = {
    serverSelectionTimeoutMS: 15000, // 15 segundos para seleccionar servidor
    socketTimeoutMS: 45000, // 45 segundos timeout de socket
    maxPoolSize: 50, // Máximo 50 conexiones simultáneas (para soportar 100+ usuarios)
    minPoolSize: 5, // Mínimo 5 conexiones activas
    maxIdleTimeMS: 30000, // Cerrar conexiones inactivas después de 30s
    retryWrites: true, // Reintentar escrituras fallidas
    retryReads: true, // Reintentar lecturas fallidas
    w: 'majority', // Write concern: mayoría de nodos
  };

  try {
    const conn = await mongoose.connect(mongoUri, options);
    
    console.log('═══════════════════════════════════════════════════════');
    console.log(`✅ MongoDB CONECTADO EXITOSAMENTE`);
    console.log(`📍 Host: ${conn.connection.host}`);
    console.log(`🗄️  Base de datos: ${conn.connection.name}`);
    console.log(`📊 Pool de conexiones: Min ${options.minPoolSize} / Max ${options.maxPoolSize}`);
    console.log(`⚡ Modo: ${process.env.NODE_ENV || 'development'}`);
    console.log('═══════════════════════════════════════════════════════');
    
    // Resetear contador de intentos de reconexión
    reconnectAttempts = 0;
    
    // ==========================================
    // EVENTOS DE CONEXIÓN MEJORADOS
    // ==========================================
    
    mongoose.connection.on('connected', () => {
      console.log(`🟢 [${new Date().toISOString()}] Mongoose conectado a MongoDB`);
    });

    mongoose.connection.on('error', (err) => {
      console.error('═══════════════════════════════════════════════════════');
      console.error(`🔴 [${new Date().toISOString()}] ERROR DE MONGOOSE`);
      console.error(`📝 Mensaje: ${err.message}`);
      console.error(`📋 Stack: ${err.stack}`);
      console.error('═══════════════════════════════════════════════════════');
    });

    mongoose.connection.on('disconnected', () => {
      console.warn('═══════════════════════════════════════════════════════');
      console.warn(`🟠 [${new Date().toISOString()}] Mongoose DESCONECTADO de MongoDB`);
      console.warn(`🔄 Intentos de reconexión: ${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS}`);
      console.warn('═══════════════════════════════════════════════════════');
      
      // Mongoose maneja reconexiones automáticamente, pero monitoreamos
      if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
        reconnectAttempts++;
        console.log(`⏳ Mongoose intentará reconectar automáticamente...`);
      } else {
        console.error('❌ ALERTA: Demasiados intentos de reconexión fallidos');
        console.error('💡 Verifica la conexión a internet y el estado de MongoDB Atlas');
      }
    });

    mongoose.connection.on('reconnected', () => {
      console.log('═══════════════════════════════════════════════════════');
      console.log(`✅ [${new Date().toISOString()}] Mongoose RECONECTADO exitosamente`);
      console.log('═══════════════════════════════════════════════════════');
      reconnectAttempts = 0; // Resetear contador
    });

    mongoose.connection.on('timeout', () => {
      console.error(`⏱️ [${new Date().toISOString()}] TIMEOUT de conexión a MongoDB`);
    });

    mongoose.connection.on('close', () => {
      console.log(`🔒 [${new Date().toISOString()}] Conexión a MongoDB cerrada`);
    });

    return conn;
    
  } catch (error) {
    console.error('═══════════════════════════════════════════════════════');
    console.error(`❌ ERROR CRÍTICO DE CONEXIÓN A MONGODB`);
    console.error(`📅 Fecha/Hora: ${new Date().toISOString()}`);
    console.error(`📝 Mensaje: ${error.message}`);
    console.error(`📋 Stack completo:`);
    console.error(error.stack);
    console.error('═══════════════════════════════════════════════════════');
    
    console.log('\n💡 POSIBLES SOLUCIONES:\n');
    
    if (mongoUri.includes('mongodb+srv')) {
      console.log('📌 Usando MongoDB Atlas (Cloud):');
      console.log('   1. Verifica que tu IP esté en la whitelist (Network Access en Atlas)');
      console.log('   2. Verifica que el usuario y password sean correctos');
      console.log('   3. Verifica que tengas conexión a internet');
      console.log('   4. Verifica que el cluster esté activo en https://cloud.mongodb.com');
    } else if (mongoUri.includes('mongodb://mongo-dev') || mongoUri.includes('docker')) {
      console.log('📌 Usando MongoDB en Docker:');
      console.log('   1. Verifica que el contenedor mongo esté corriendo:');
      console.log('      docker ps | grep mongo');
      console.log('   2. Reinicia los contenedores:');
      console.log('      docker compose -f docker-compose.dev.yml restart');
    } else {
      console.log('📌 Usando MongoDB local:');
      console.log('   1. Verifica que MongoDB esté corriendo localmente');
      console.log('   2. Verifica la URI en .env');
    }
    
    console.log('\n⚠️  El servidor continuará funcionando pero SIN base de datos');
    console.log('⚠️  Las solicitudes a la API fallarán hasta que MongoDB se conecte\n');
    
    // En producción, salir del proceso; en desarrollo, continuar
    if (process.env.NODE_ENV === 'production') {
      console.error('🛑 Modo producción: Terminando proceso...');
      process.exit(1);
    } else {
      console.log('🔧 Modo desarrollo: Continuando sin DB (solo para debugging)...');
    }
  }
};

module.exports = connectDB;