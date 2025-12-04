// routes/driverDocuments.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { protect } = require('../middleware/auth');
const {
  uploadDriverDocument,
  getDriverDocuments,
  deleteDriverDocument,
  checkDriverDocumentsStatus
} = require('../controllers/driverDocumentController');

// Configurar multer para almacenar archivos
const storageConfig = require('../config/storage');
const DOCUMENTS_DIR = storageConfig.DOCUMENTS_DIR;

const multerStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Usar el directorio de almacenamiento configurado
    if (!fs.existsSync(DOCUMENTS_DIR)) {
      fs.mkdirSync(DOCUMENTS_DIR, { recursive: true });
    }
    cb(null, DOCUMENTS_DIR);
  },
  filename: (req, file, cb) => {
    // Generar nombre único: userId_timestamp_tipo.extension
    const userId = req.user._id.toString();
    const timestamp = Date.now();
    const tipo = req.body.tipoDocumento?.replace(/\s+/g, '_') || 'documento';
    const ext = path.extname(file.originalname);
    cb(null, `${userId}_${timestamp}_${tipo}${ext}`);
  }
});

// Filtro para aceptar solo imágenes
const fileFilter = (req, file, cb) => {
  console.log(`📎 [Multer] Archivo recibido: ${file.originalname}, tipo: ${file.mimetype}`);
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    console.error(`❌ [Multer] Tipo de archivo no permitido: ${file.mimetype}`);
    cb(new Error('Solo se permiten archivos de imagen'), false);
  }
};

const upload = multer({
  storage: multerStorage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5 MB máximo
  }
});

// Middleware para manejar errores de multer
const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    console.error(`❌ [Multer Error] ${err.message}`);
    return res.status(400).json({ 
      message: `Error al subir archivo: ${err.message}` 
    });
  }
  if (err) {
    console.error(`❌ [Upload Error] ${err.message}`);
    return res.status(400).json({ 
      message: err.message || 'Error al procesar el archivo' 
    });
  }
  next();
};

// Ruta de prueba para verificar que el router funciona
router.get('/test', (req, res) => {
  res.json({ message: 'Ruta driver-documents funciona correctamente' });
});

// Rutas
// IMPORTANTE: El orden de los middlewares es crítico
// 1. protect (autenticación)
// 2. upload.single('imagen') (multer para procesar el archivo)
// 3. handleMulterError (manejo de errores de multer)
// 4. uploadDriverDocument (controlador)
router.post(
  '/upload',
  protect,
  upload.single('imagen'),
  handleMulterError,
  uploadDriverDocument
);

router.get(
  '/',
  protect,
  getDriverDocuments
);

router.get(
  '/status',
  protect,
  checkDriverDocumentsStatus
);

router.delete(
  '/:tipoDocumento',
  protect,
  deleteDriverDocument
);

module.exports = router;

