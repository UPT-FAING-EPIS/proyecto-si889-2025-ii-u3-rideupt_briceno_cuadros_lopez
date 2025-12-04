// controllers/driverDocumentController.js
const User = require('../models/User');
const fs = require('fs');
const path = require('path');
const storage = require('../config/storage');
const DOCUMENTS_DIR = storage.DOCUMENTS_DIR;
const getDocumentPath = storage.getDocumentPath;
const getDocumentUrl = storage.getDocumentUrl;
const deleteStorageFile = storage.deleteFile;

/**
 * Subir y validar un documento del conductor
 */
exports.uploadDriverDocument = async (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`📤 [${timestamp}] ==========================================`);
  console.log(`📤 [${timestamp}] Subiendo documento de conductor`);
  console.log(`📤 [${timestamp}] Usuario: ${req.user?._id || 'NO AUTENTICADO'}`);
  console.log(`📤 [${timestamp}] Método: ${req.method}`);
  console.log(`📤 [${timestamp}] Ruta: ${req.path}`);
  console.log(`📤 [${timestamp}] Archivo recibido: ${req.file ? 'SÍ' : 'NO'}`);
  console.log(`📤 [${timestamp}] Body:`, req.body);
  console.log(`📤 [${timestamp}] ==========================================`);
  
  try {
    if (!req.file) {
      console.error(`❌ [${timestamp}] No se recibió ningún archivo`);
      return res.status(400).json({ message: 'No se proporcionó ninguna imagen' });
    }

    const { tipoDocumento } = req.body;
    
    if (!tipoDocumento || !['Foto del Vehículo', 'Tarjeta de Propiedad', 'Carnet Universitario', 'Selfie del Conductor'].includes(tipoDocumento)) {
      // Eliminar archivo si el tipo es inválido
      if (req.file.path) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(400).json({ message: 'Tipo de documento inválido' });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      if (req.file.path) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // Mover el archivo del directorio temporal al almacenamiento permanente
    const finalPath = getDocumentPath(req.file.filename);
    
    // Si el archivo ya está en el lugar correcto (por multer), no hacer nada
    // Si está en otro lugar, moverlo
    if (req.file.path !== finalPath) {
      // Crear directorio si no existe
      const finalDir = path.dirname(finalPath);
      if (!fs.existsSync(finalDir)) {
        fs.mkdirSync(finalDir, { recursive: true });
      }
      
      // Mover archivo
      fs.renameSync(req.file.path, finalPath);
      console.log(`📦 [${timestamp}] Archivo movido a almacenamiento permanente: ${finalPath}`);
    }

    // Guardar URL pública de la imagen (absoluta para que funcione desde el frontend web)
    const imageUrl = getDocumentUrl(req.file.filename, req);

    // Buscar si ya existe un documento del mismo tipo
    const existingDocIndex = user.driverDocuments.findIndex(
      doc => doc.tipoDocumento === tipoDocumento
    );

    const documentData = {
      tipoDocumento,
      urlImagen: imageUrl,
      subidoEn: new Date()
    };

    if (existingDocIndex >= 0) {
      // Eliminar imagen anterior si existe
      const oldDoc = user.driverDocuments[existingDocIndex];
      if (oldDoc.urlImagen) {
        // Extraer el nombre del archivo de la URL
        const oldFilename = oldDoc.urlImagen.split('/').pop();
        const oldPath = getDocumentPath(oldFilename);
        deleteStorageFile(oldPath);
      }
      // Actualizar documento existente
      user.driverDocuments[existingDocIndex] = documentData;
    } else {
      // Agregar nuevo documento
      user.driverDocuments.push(documentData);
    }

    await user.save();

    console.log(`✅ [${timestamp}] Documento subido exitosamente`);
    console.log(`   📄 Tipo: ${tipoDocumento}`);

    res.json({
      message: 'Documento subido exitosamente. Esperando aprobación del administrador.',
      documento: documentData
    });

  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al subir documento: ${error.message}`);
    
    // Eliminar archivo en caso de error
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (unlinkError) {
        console.error(`Error al eliminar archivo: ${unlinkError.message}`);
      }
    }
    
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

/**
 * Obtener todos los documentos del conductor
 */
exports.getDriverDocuments = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('driverDocuments');
    
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // Convertir URLs relativas a absolutas
    const documentos = (user.driverDocuments || []).map(doc => {
      const docObj = doc.toObject ? doc.toObject() : doc;
      if (docObj.urlImagen && !docObj.urlImagen.startsWith('http')) {
        // Extraer el nombre del archivo de la URL relativa
        const filename = docObj.urlImagen.split('/').pop();
        docObj.urlImagen = getDocumentUrl(filename, req);
      }
      return docObj;
    });

    res.json({
      documentos: documentos
    });
  } catch (error) {
    console.error(`Error al obtener documentos: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

/**
 * Eliminar un documento del conductor
 */
exports.deleteDriverDocument = async (req, res) => {
  const timestamp = new Date().toISOString();
  const { tipoDocumento } = req.params;
  
  try {
    const user = await User.findById(req.user._id);
    
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    const docIndex = user.driverDocuments.findIndex(
      doc => doc.tipoDocumento === tipoDocumento
    );

    if (docIndex === -1) {
      return res.status(404).json({ message: 'Documento no encontrado' });
    }

    // Eliminar archivo físico
    const doc = user.driverDocuments[docIndex];
    if (doc.urlImagen) {
      // Extraer el nombre del archivo de la URL
      const filename = doc.urlImagen.split('/').pop();
      const filePath = getDocumentPath(filename);
      deleteStorageFile(filePath);
    }

    // Eliminar del array
    user.driverDocuments.splice(docIndex, 1);
    await user.save();

    console.log(`✅ [${timestamp}] Documento eliminado: ${tipoDocumento}`);
    res.json({ message: 'Documento eliminado exitosamente' });

  } catch (error) {
    console.error(`🔴 [${timestamp}] Error al eliminar documento: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};


/**
 * Verificar si todos los documentos requeridos están subidos
 */
exports.checkDriverDocumentsStatus = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('driverDocuments isDriverProfileComplete driverApprovalStatus driverRejectionReason');
    
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    const requiredDocs = ['Foto del Vehículo', 'Tarjeta de Propiedad', 'Carnet Universitario'];
    const optionalDocs = ['Selfie del Conductor'];
    
    const status = {
      documentosRequeridos: {},
      documentosOpcionales: {},
      todosSubidos: true,
      puedeConvertirseEnConductor: false,
      approvalStatus: user.driverApprovalStatus || 'pending',
      rejectionReason: user.driverRejectionReason || null
    };

    // Verificar documentos requeridos
    for (const docType of requiredDocs) {
      const doc = user.driverDocuments.find(d => d.tipoDocumento === docType);
      status.documentosRequeridos[docType] = {
        subido: !!doc
      };
      
      if (!status.documentosRequeridos[docType].subido) {
        status.todosSubidos = false;
      }
    }

    // Verificar documentos opcionales
    for (const docType of optionalDocs) {
      const doc = user.driverDocuments.find(d => d.tipoDocumento === docType);
      status.documentosOpcionales[docType] = {
        subido: !!doc
      };
    }

    // Puede convertirse en conductor si todos los requeridos están subidos
    status.puedeConvertirseEnConductor = status.todosSubidos;

    res.json(status);
  } catch (error) {
    console.error(`Error al verificar estado de documentos: ${error.message}`);
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

