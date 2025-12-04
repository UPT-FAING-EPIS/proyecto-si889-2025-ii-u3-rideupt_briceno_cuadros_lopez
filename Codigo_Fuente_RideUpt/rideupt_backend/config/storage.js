// config/storage.js
// Configuración de almacenamiento de archivos fuera de Docker

const path = require('path');
const fs = require('fs');

/**
 * Obtiene la URL base del servidor desde el request o variables de entorno
 * @param {Object} req - Request object de Express
 * @returns {string} URL base del servidor
 */
function getBaseUrl(req = null) {
  // Si hay una variable de entorno con la URL del servidor, usarla (prioridad máxima)
  if (process.env.SERVER_URL) {
    const serverUrl = process.env.SERVER_URL.replace(/\/$/, '');
    console.log(`🔗 [Storage] Usando SERVER_URL de entorno: ${serverUrl}`);
    return serverUrl;
  }
  
  // Si hay un request, intentar obtener la URL desde él
  if (req) {
    // En producción, verificar headers del proxy primero
    let protocol = 'http';
    let host = 'localhost:3000';
    
    // Detectar protocolo desde headers del proxy (para producción detrás de nginx/apache)
    // nginx normalmente envía x-forwarded-proto
    if (req.headers['x-forwarded-proto']) {
      protocol = req.headers['x-forwarded-proto'].split(',')[0].trim();
      console.log(`🔗 [Storage] Protocolo detectado desde x-forwarded-proto: ${protocol}`);
    } else if (req.headers['x-forwarded-ssl'] === 'on') {
      protocol = 'https';
      console.log(`🔗 [Storage] Protocolo detectado desde x-forwarded-ssl: https`);
    } else if (req.secure || req.protocol === 'https') {
      protocol = 'https';
      console.log(`🔗 [Storage] Protocolo detectado desde req.secure: https`);
    } else {
      protocol = req.protocol || 'http';
      console.log(`🔗 [Storage] Protocolo por defecto: ${protocol}`);
    }
    
    // Detectar host desde headers del proxy
    if (req.headers['x-forwarded-host']) {
      host = req.headers['x-forwarded-host'].split(',')[0].trim();
      console.log(`🔗 [Storage] Host detectado desde x-forwarded-host: ${host}`);
    } else if (req.headers['x-original-host']) {
      host = req.headers['x-original-host'];
      console.log(`🔗 [Storage] Host detectado desde x-original-host: ${host}`);
    } else if (req.get('host')) {
      host = req.get('host');
      console.log(`🔗 [Storage] Host detectado desde req.get('host'): ${host}`);
    } else if (req.headers.host) {
      host = req.headers.host;
      console.log(`🔗 [Storage] Host detectado desde req.headers.host: ${host}`);
    }
    
    // Si el host contiene rideupt.sytes.net, forzar HTTPS
    if (host.includes('rideupt.sytes.net')) {
      protocol = 'https';
      // Asegurar que no tenga puerto en HTTPS (nginx maneja el puerto)
      if (host.includes(':3000') || host.includes(':443')) {
        host = 'rideupt.sytes.net';
      }
      console.log(`🔗 [Storage] Detectado dominio rideupt.sytes.net, forzando HTTPS`);
    }
    
    // En producción, si el origin viene de rideupt.web.app, usar el dominio del backend
    const origin = req.headers.origin;
    if (origin && (origin.includes('rideupt.web.app') || origin.includes('rideupt.firebaseapp.com'))) {
      // Si el backend está en rideupt.sytes.net, usar ese dominio
      if (host.includes('rideupt.sytes.net') || process.env.NODE_ENV === 'production') {
        const backendUrl = 'https://rideupt.sytes.net';
        console.log(`🔗 [Storage] Usando dominio del backend para frontend web: ${backendUrl}`);
        return backendUrl;
      }
    }
    
    const baseUrl = `${protocol}://${host}`;
    console.log(`🔗 [Storage] URL base generada: ${baseUrl} (protocol: ${protocol}, host: ${host})`);
    return baseUrl;
  }
  
  // Fallback: en producción, usar el dominio conocido
  if (process.env.NODE_ENV === 'production') {
    const productionUrl = 'https://rideupt.sytes.net';
    console.log(`🔗 [Storage] Fallback producción: ${productionUrl}`);
    return productionUrl;
  }
  
  // Fallback desarrollo: usar localhost
  return 'http://localhost:3000';
}

// Directorio base para almacenamiento (fuera de Docker)
// Este directorio debe estar montado como volumen en Docker
// IMPORTANTE: Este directorio DEBE existir en el servidor host antes de iniciar Docker
const STORAGE_BASE_DIR = process.env.STORAGE_BASE_DIR || '/var/rideupt/storage';

// Directorios específicos
const DOCUMENTS_DIR = path.join(STORAGE_BASE_DIR, 'documents');
const PROFILES_DIR = path.join(STORAGE_BASE_DIR, 'profiles');

/**
 * Inicializa los directorios de almacenamiento
 */
function initializeStorage() {
  const timestamp = new Date().toISOString();
  console.log(`📁 [${timestamp}] Inicializando almacenamiento...`);
  console.log(`   📂 Directorio base: ${STORAGE_BASE_DIR}`);
  
  // Verificar si el directorio base existe (debe estar montado desde el host)
  if (!fs.existsSync(STORAGE_BASE_DIR)) {
    console.error(`   ❌ ERROR: El directorio ${STORAGE_BASE_DIR} no existe en el host`);
    console.error(`   💡 SOLUCIÓN: Crea el directorio en el servidor antes de iniciar Docker:`);
    console.error(`      sudo mkdir -p ${STORAGE_BASE_DIR}/documents`);
    console.error(`      sudo mkdir -p ${STORAGE_BASE_DIR}/profiles`);
    console.error(`      sudo chown -R 1001:1001 ${STORAGE_BASE_DIR}  # UID del usuario nodejs en el contenedor`);
    console.error(`      sudo chmod -R 755 ${STORAGE_BASE_DIR}`);
    console.error(`   🔄 Usando directorio local como fallback temporal...`);
    
    // Usar directorio local como fallback
    const fallbackDir = path.join(__dirname, '../uploads/documents');
    if (!fs.existsSync(fallbackDir)) {
      try {
        fs.mkdirSync(fallbackDir, { recursive: true });
        console.log(`   ⚠️  Fallback creado: ${fallbackDir}`);
      } catch (fallbackError) {
        console.error(`   ❌ Error crítico: No se pudo crear ningún directorio de almacenamiento`);
        console.error(`   📝 Error: ${fallbackError.message}`);
        return false;
      }
    }
    return false;
  }
  
  // Crear subdirectorios si no existen
  const subdirectories = [DOCUMENTS_DIR, PROFILES_DIR];
  let allCreated = true;
  
  subdirectories.forEach(dir => {
    if (!fs.existsSync(dir)) {
      try {
        fs.mkdirSync(dir, { recursive: true });
        console.log(`   ✅ Directorio creado: ${dir}`);
      } catch (error) {
        console.error(`   ❌ Error al crear directorio ${dir}: ${error.message}`);
        allCreated = false;
      }
    } else {
      console.log(`   ✓ Directorio existe: ${dir}`);
    }
  });
  
  // Verificar permisos de escritura
  let writable = false;
  try {
    const testFile = path.join(DOCUMENTS_DIR, '.test');
    fs.writeFileSync(testFile, 'test');
    fs.unlinkSync(testFile);
    console.log(`   ✅ Permisos de escritura verificados`);
    writable = true;
  } catch (error) {
    console.error(`   ❌ Error de permisos en ${DOCUMENTS_DIR}: ${error.message}`);
    console.error(`   💡 Verifica los permisos del directorio en el servidor host`);
    writable = false;
  }
  
  if (allCreated && writable) {
    console.log(`📁 [${timestamp}] ✅ Almacenamiento inicializado correctamente`);
    return true;
  } else {
    console.log(`📁 [${timestamp}] ⚠️  Almacenamiento inicializado con advertencias`);
    return false;
  }
}

/**
 * Obtiene la ruta completa para guardar un documento
 */
function getDocumentPath(filename) {
  return path.join(DOCUMENTS_DIR, filename);
}

/**
 * Obtiene la URL pública para acceder a un documento
 * @param {string} filename - Nombre del archivo
 * @param {Object|string} reqOrBaseUrl - Request object de Express o URL base del servidor (opcional)
 * @returns {string} URL del documento
 */
function getDocumentUrl(filename, reqOrBaseUrl = null) {
  const relativeUrl = `/uploads/documents/${filename}`;
  
  // Determinar la URL base
  let baseUrl = null;
  
  if (reqOrBaseUrl) {
    // Si es un objeto (request), usar getBaseUrl
    if (typeof reqOrBaseUrl === 'object' && reqOrBaseUrl.get) {
      baseUrl = getBaseUrl(reqOrBaseUrl);
    } 
    // Si es un string, usarlo directamente
    else if (typeof reqOrBaseUrl === 'string') {
      baseUrl = reqOrBaseUrl.replace(/\/$/, '');
    }
  }
  
  // Si no se proporcionó baseUrl, intentar obtenerla de variables de entorno
  if (!baseUrl) {
    baseUrl = getBaseUrl();
  }
  
  // SIEMPRE devolver URL absoluta si tenemos una baseUrl válida
  // Esto es crítico para que funcione desde el frontend web
  if (baseUrl) {
    const absoluteUrl = `${baseUrl}${relativeUrl}`;
    console.log(`🔗 [Storage] URL de documento generada: ${absoluteUrl} (archivo: ${filename})`);
    return absoluteUrl;
  }
  
  // Por defecto, devolver URL relativa (solo en desarrollo local)
  console.log(`⚠️  [Storage] No se pudo determinar baseUrl, usando URL relativa: ${relativeUrl}`);
  return relativeUrl;
}

/**
 * Verifica si un archivo existe
 */
function fileExists(filepath) {
  return fs.existsSync(filepath);
}

/**
 * Elimina un archivo de forma segura
 */
function deleteFile(filepath) {
  try {
    if (fs.existsSync(filepath)) {
      fs.unlinkSync(filepath);
      return true;
    }
    return false;
  } catch (error) {
    console.error(`Error al eliminar archivo ${filepath}: ${error.message}`);
    return false;
  }
}

/**
 * Obtiene información del almacenamiento
 */
function getStorageInfo() {
  try {
    const stats = fs.statSync(STORAGE_BASE_DIR);
    return {
      baseDir: STORAGE_BASE_DIR,
      documentsDir: DOCUMENTS_DIR,
      profilesDir: PROFILES_DIR,
      exists: true,
      writable: fs.accessSync(STORAGE_BASE_DIR, fs.constants.W_OK) === undefined
    };
  } catch (error) {
    return {
      baseDir: STORAGE_BASE_DIR,
      documentsDir: DOCUMENTS_DIR,
      profilesDir: PROFILES_DIR,
      exists: false,
      writable: false,
      error: error.message
    };
  }
}

module.exports = {
  STORAGE_BASE_DIR,
  DOCUMENTS_DIR,
  PROFILES_DIR,
  initializeStorage,
  getDocumentPath,
  getDocumentUrl,
  getBaseUrl,
  fileExists,
  deleteFile,
  getStorageInfo
};

