// server.js
const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');
const connectDB = require('./config/database');
const { initializeSocket } = require('./services/socketService');
const { initializeFCM } = require('./services/notificationService');
const { initializeStorage, DOCUMENTS_DIR } = require('./config/storage');

// ==========================================
// CONFIGURACIÓN INICIAL
// ==========================================
dotenv.config();

console.log('═══════════════════════════════════════════════════════');
console.log('🚀 INICIANDO RIDEUPT BACKEND');
console.log(`📅 Fecha/Hora: ${new Date().toISOString()}`);
console.log(`⚡ Modo: ${process.env.NODE_ENV || 'development'}`);
console.log(`🔧 Puerto: ${process.env.PORT || 3000}`);
console.log('═══════════════════════════════════════════════════════');

// ==========================================
// INICIALIZAR SERVICIOS
// ==========================================
connectDB();
initializeFCM();
initializeStorage(); // Inicializar almacenamiento de archivos

// ==========================================
// CONFIGURAR EXPRESS Y SOCKET.IO
// ==========================================
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // En producción, configura dominios específicos
    methods: ["GET", "POST"],
    credentials: true
  },
  // Configuración para manejar muchas conexiones
  pingTimeout: 60000, // 60 segundos
  pingInterval: 25000, // 25 segundos
  maxHttpBufferSize: 1e8, // 100 MB
  transports: ['websocket', 'polling']
});

initializeSocket(io);

// ==========================================
// MIDDLEWARES
// ==========================================
// Configurar CORS para permitir acceso desde la web
const allowedOrigins = [
  'https://rideupt.web.app',
  'https://rideupt.firebaseapp.com',
  'http://localhost:3000',
  'http://localhost:8080',
  'http://127.0.0.1:8080',
  'http://localhost:5000',
  'http://127.0.0.1:5000',
];

app.use(cors({
  origin: function (origin, callback) {
    // Log para debug
    console.log(`🔍 [CORS] Petición recibida - Origin: ${origin || 'null (sin origin)'}`);
    console.log(`🔍 [CORS] NODE_ENV: ${process.env.NODE_ENV || 'development'}`);
    
    // Permitir requests sin origin (como Postman, aplicaciones móviles, o Flutter web en algunos casos)
    if (!origin) {
      console.log('✅ [CORS] Permitiendo petición sin origin');
      return callback(null, true);
    }
    
    // SIEMPRE permitir localhost y 127.0.0.1 (para desarrollo web)
    if (origin.startsWith('http://localhost') || 
        origin.startsWith('http://127.0.0.1') ||
        origin.startsWith('https://localhost') ||
        origin.startsWith('https://127.0.0.1')) {
      console.log(`✅ [CORS] Origen localhost permitido: ${origin}`);
      return callback(null, true);
    }
    
    // En producción, verificar orígenes permitidos adicionales
    if (process.env.NODE_ENV === 'production') {
      // Permitir orígenes específicos de Firebase
      const isAllowed = allowedOrigins.indexOf(origin) !== -1 || 
          origin.startsWith('https://rideupt.') ||
          origin.includes('firebaseapp.com') ||
          origin.includes('rideupt.web.app') ||
          origin.includes('rideupt.firebaseapp.com');
      
      if (isAllowed) {
        console.log(`✅ [CORS] Origen permitido (producción): ${origin}`);
        callback(null, true);
      } else {
        console.warn(`⚠️  [CORS] Origen bloqueado (producción): ${origin}`);
        console.warn(`⚠️  [CORS] Orígenes permitidos: ${allowedOrigins.join(', ')}`);
        callback(new Error('Not allowed by CORS'));
      }
    } else {
      // En desarrollo, permitir TODOS los orígenes
      console.log(`✅ [CORS] Origen permitido (desarrollo): ${origin}`);
      callback(null, true);
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  exposedHeaders: ['Content-Type', 'Authorization'],
  preflightContinue: false,
  optionsSuccessStatus: 204,
}));
// Configurar trust proxy para detectar protocolo correcto en producción (detrás de nginx/proxy)
// Esto permite que req.protocol y req.get('host') funcionen correctamente
// Siempre confiar en el proxy para que funcione tanto en desarrollo como producción
app.set('trust proxy', true);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Servir archivos estáticos (imágenes de documentos)
// Esto permite que el panel web pueda acceder a las imágenes
app.use('/uploads/documents', express.static(DOCUMENTS_DIR, {
  maxAge: '1y', // Cache por 1 año
  etag: true,
  lastModified: true,
  setHeaders: (res, path) => {
    // Permitir CORS para imágenes
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET');
  }
}));

// Ruta de prueba para verificar que los archivos se sirven correctamente
app.get('/test-image/:filename', (req, res) => {
  const { filename } = req.params;
  const filePath = path.join(DOCUMENTS_DIR, filename);
  const fs = require('fs');
  
  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).json({ 
      message: 'Archivo no encontrado',
      filename,
      documentsDir: DOCUMENTS_DIR,
      filePath
    });
  }
});

// Middleware de logging de requests (antes de CORS para capturar el origen)
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  const origin = req.headers.origin || 'N/A';
  const userAgent = req.headers['user-agent'] || 'N/A';
  console.log(`📨 [${timestamp}] ${req.method} ${req.path} - IP: ${req.ip}`);
  console.log(`   🌐 Origin: ${origin}`);
  if (req.method === 'OPTIONS') {
    console.log(`   🔍 Preflight request (OPTIONS) - User-Agent: ${userAgent.substring(0, 50)}...`);
  }
  next();
});

// ==========================================
// RUTA DE SALUD (HEALTH CHECK)
// ==========================================
app.get('/health', (req, res) => {
  const dbStatus = require('mongoose').connection.readyState;
  const dbStatusMap = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting'
  };
  
  const { getStorageInfo } = require('./config/storage');
  const storageInfo = getStorageInfo();
  
  // Log para debug
  const timestamp = new Date().toISOString();
  console.log(`📊 [${timestamp}] Health check - IP: ${req.ip}, Origin: ${req.headers.origin || 'N/A'}`);
  
  res.json({
    status: 'ok',
    timestamp: timestamp,
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    database: {
      status: dbStatusMap[dbStatus],
      connected: dbStatus === 1
    },
    storage: storageInfo,
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + ' MB',
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + ' MB'
    }
  });
});

// ==========================================
// RUTAS DE API
// ==========================================
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/trips', require('./routes/trips'));
app.use('/api/ratings', require('./routes/ratings'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/driver-documents', require('./routes/driverDocuments'));
app.use('/api/admin', require('./routes/admin'));


// ==========================================
// RUTA 404 - NO ENCONTRADA
// ==========================================
app.use((req, res) => {
  console.warn(`⚠️  [${new Date().toISOString()}] Ruta no encontrada: ${req.method} ${req.path}`);
  res.status(404).json({
    error: 'Ruta no encontrada',
    path: req.path,
    method: req.method
  });
});

// ==========================================
// MIDDLEWARE DE MANEJO DE ERRORES GLOBAL
// ==========================================
app.use((err, req, res, next) => {
  console.error('═══════════════════════════════════════════════════════');
  console.error(`🔴 ERROR NO MANEJADO [${new Date().toISOString()}]`);
  console.error(`📍 Ruta: ${req.method} ${req.path}`);
  console.error(`📝 Mensaje: ${err.message}`);
  console.error(`📋 Stack:`);
  console.error(err.stack);
  console.error('═══════════════════════════════════════════════════════');

  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' 
      ? 'Error interno del servidor' 
      : err.message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
});

// ==========================================
// INICIAR SERVIDOR
// ==========================================
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0'; // Escuchar en todas las interfaces para Docker
server.listen(PORT, HOST, () => {
  console.log('═══════════════════════════════════════════════════════');
  console.log(`✅ SERVIDOR CORRIENDO EXITOSAMENTE`);
  console.log(`🌐 Puerto: ${PORT}`);
  console.log(`🔗 HTTP: http://localhost:${PORT}`);
  console.log(`🔌 WebSockets: Habilitado`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log('═══════════════════════════════════════════════════════');
});

// ==========================================
// MANEJO DE ERRORES DE PROCESO
// ==========================================
process.on('unhandledRejection', (reason, promise) => {
  console.error('═══════════════════════════════════════════════════════');
  console.error(`🔴 PROMESA NO MANEJADA RECHAZADA [${new Date().toISOString()}]`);
  console.error('📝 Razón:', reason);
  console.error('📋 Promesa:', promise);
  console.error('═══════════════════════════════════════════════════════');
  // No salir en producción, solo loggear
  if (process.env.NODE_ENV !== 'production') {
    console.log('⚠️  En producción, esto debería ser monitoreado');
  }
});

process.on('uncaughtException', (error) => {
  console.error('═══════════════════════════════════════════════════════');
  console.error(`🔴 EXCEPCIÓN NO CAPTURADA [${new Date().toISOString()}]`);
  console.error('📝 Error:', error.message);
  console.error('📋 Stack:', error.stack);
  console.error('═══════════════════════════════════════════════════════');
  // En caso de excepción no capturada, es mejor reiniciar
  console.error('🛑 Cerrando el servidor de forma segura...');
  server.close(() => {
    console.log('🔒 Servidor cerrado. Saliendo del proceso.');
    process.exit(1);
  });
  // Forzar cierre después de 10 segundos si no se cierra naturalmente
  setTimeout(() => {
    console.error('⏱️ Tiempo de espera agotado. Forzando cierre...');
    process.exit(1);
  }, 10000);
});

process.on('SIGTERM', () => {
  console.log('═══════════════════════════════════════════════════════');
  console.log(`🛑 SEÑAL SIGTERM RECIBIDA [${new Date().toISOString()}]`);
  console.log('🔒 Cerrando el servidor de forma segura...');
  console.log('═══════════════════════════════════════════════════════');
  server.close(() => {
    console.log('✅ Servidor cerrado exitosamente');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('═══════════════════════════════════════════════════════');
  console.log(`🛑 SEÑAL SIGINT RECIBIDA [${new Date().toISOString()}]`);
  console.log('🔒 Cerrando el servidor de forma segura...');
  console.log('═══════════════════════════════════════════════════════');
  server.close(() => {
    console.log('✅ Servidor cerrado exitosamente');
    process.exit(0);
  });
});
