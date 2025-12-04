// controllers/authController.js
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const admin = require('firebase-admin');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

exports.register = async (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`📝 [${timestamp}] Intento de registro - Email: ${req.body.email}`);
  
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    console.warn(`⚠️  [${timestamp}] Errores de validación en registro:`, errors.array());
    return res.status(400).json({ errors: errors.array() });
  }

  const { firstName, lastName, email, password, phone, university, studentId } = req.body;

  try {
    const userExists = await User.findOne({ email });
    if (userExists) {
      console.warn(`⚠️  [${timestamp}] Intento de registro con email existente: ${email}`);
      return res.status(400).json({ message: 'El correo electrónico ya está en uso' });
    }

    const user = await User.create({ firstName, lastName, email, password, phone, university, studentId });

    if (user) {
      console.log(`✅ [${timestamp}] Usuario registrado exitosamente: ${user._id} - ${email}`);
      res.status(201).json({
        _id: user._id,
        firstName: user.firstName,
        email: user.email,
        role: user.role,
        token: generateToken(user._id),
      });
    } else {
      console.error(`❌ [${timestamp}] Error al crear usuario - Datos inválidos`);
      res.status(400).json({ message: 'Datos de usuario inválidos' });
    }
  } catch (error) {
    console.error('═══════════════════════════════════════════════════════');
    console.error(`🔴 ERROR EN REGISTRO [${timestamp}]`);
    console.error(`📧 Email: ${email}`);
    console.error(`📝 Mensaje: ${error.message}`);
    console.error(`📋 Stack: ${error.stack}`);
    console.error('═══════════════════════════════════════════════════════');
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

exports.login = async (req, res) => {
  const timestamp = new Date().toISOString();
  const { email, password } = req.body;
  
  console.log(`🔐 [${timestamp}] Intento de login - Email: ${email}`);
  
  try {
    const user = await User.findOne({ email });

    if (!user) {
      console.warn(`⚠️  [${timestamp}] Login fallido - Usuario no encontrado: ${email}`);
      return res.status(401).json({ message: 'Correo o contraseña inválidos' });
    }

    const isPasswordValid = await user.comparePassword(password);
    
    if (isPasswordValid) {
      console.log(`✅ [${timestamp}] Login exitoso - Usuario: ${user._id} - ${email} - Rol: ${user.role}`);
      res.json({
        _id: user._id,
        firstName: user.firstName,
        email: user.email,
        role: user.role,
        token: generateToken(user._id),
      });
    } else {
      console.warn(`⚠️  [${timestamp}] Login fallido - Contraseña incorrecta: ${email}`);
      res.status(401).json({ message: 'Correo o contraseña inválidos' });
    }
  } catch (error) {
    console.error('═══════════════════════════════════════════════════════');
    console.error(`🔴 ERROR EN LOGIN [${timestamp}]`);
    console.error(`📧 Email: ${email}`);
    console.error(`📝 Mensaje: ${error.message}`);
    console.error(`📋 Stack: ${error.stack}`);
    console.error('═══════════════════════════════════════════════════════');
    res.status(500).json({ message: `Error del servidor: ${error.message}` });
  }
};

// ==========================================
// GOOGLE SIGN-IN
// ==========================================
exports.googleSignIn = async (req, res) => {
  const timestamp = new Date().toISOString();
  const { idToken } = req.body;
  
  console.log('═══════════════════════════════════════════════════════');
  console.log(`🔐 [${timestamp}] GOOGLE SIGN-IN - Intento de autenticacion`);
  console.log('═══════════════════════════════════════════════════════');
  
  if (!idToken) {
    console.error(`❌ [${timestamp}] Token no proporcionado`);
    return res.status(400).json({ message: 'Token de Google requerido' });
  }
  
  try {
    // 1. Verificar el token de Firebase
    console.log(`🔍 [${timestamp}] Verificando token de Firebase...`);
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    const { email, name, uid, picture } = decodedToken;
    console.log(`✅ [${timestamp}] Token verificado exitosamente`);
    console.log(`   📧 Email: ${email}`);
    console.log(`   👤 Nombre: ${name}`);
    console.log(`   🆔 UID: ${uid}`);
    
    // 2. Verificar que sea email institucional (OPCIONAL - ajusta segun necesites)
    const isInstitutionalEmail = email.endsWith('@virtual.upt.pe');
    
    if (!isInstitutionalEmail) {
      console.warn(`⚠️  [${timestamp}] Email no institucional detectado: ${email}`);
      console.warn(`   💡 TIP: Para permitir cualquier email, comenta esta validacion`);
      
      // OPCIONAL: Comentar estas lineas si quieres permitir cualquier email de Gmail
      return res.status(400).json({ 
        message: 'Solo se permiten correos institucionales (@virtual.upt.pe)',
        details: 'Usa tu correo estudiantil de la UPT'
      });
    }
    
    console.log(`✅ [${timestamp}] Email institucional verificado`);
    
    // 3. Buscar usuario existente
    let user = await User.findOne({ email });
    
    if (user) {
      // ==========================================
      // USUARIO EXISTENTE - LOGIN
      // ==========================================
      console.log(`🔓 [${timestamp}] Usuario existente encontrado`);
      console.log(`   🆔 ID: ${user._id}`);
      console.log(`   👤 Nombre: ${user.firstName} ${user.lastName}`);
      console.log(`   🎭 Rol: ${user.role}`);
      
      return res.json({
        _id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        role: user.role,
        isAdmin: user.isAdmin || false,
        phone: user.phone,
        university: user.university,
        studentId: user.studentId,
        profilePhoto: user.profilePhoto,
        token: generateToken(user._id),
        isNewUser: false,
      });
      
    } else {
      // ==========================================
      // USUARIO NUEVO - REGISTRO AUTOMATICO
      // ==========================================
      console.log(`📝 [${timestamp}] Usuario nuevo - Creando cuenta automaticamente`);
      
      // Extraer nombre y apellido del nombre completo de Google
      const nameParts = (name || email.split('@')[0]).split(' ');
      const firstName = nameParts[0] || 'Usuario';
      const lastName = nameParts.slice(1).join(' ') || 'UPT';
      
      // Extraer codigo de estudiante del email
      // Ejemplo: jb2017059611@virtual.upt.pe -> 2017059611
      const studentIdMatch = email.match(/[a-z]+(\d+)@/i);
      const studentId = studentIdMatch ? studentIdMatch[1] : 'N/A';
      
      console.log(`   👤 Nombre extraido: ${firstName} ${lastName}`);
      console.log(`   🎓 Codigo estudiante: ${studentId}`);
      
      // Crear nuevo usuario
      user = await User.create({
        firstName,
        lastName,
        email,
        password: uid, // Usar UID de Firebase como password (no se usara para login)
        phone: 'Pendiente', // Se pedira despues
        university: 'UPT', // Universidad Privada de Tacna
        studentId,
        profilePhoto: picture || 'default_avatar.png',
        role: 'passenger', // Por defecto pasajero
      });
      
      console.log('═══════════════════════════════════════════════════════');
      console.log(`✅ [${timestamp}] USUARIO REGISTRADO CON GOOGLE EXITOSAMENTE`);
      console.log(`   🆔 ID: ${user._id}`);
      console.log(`   📧 Email: ${email}`);
      console.log(`   👤 Nombre: ${firstName} ${lastName}`);
      console.log(`   🎭 Rol: passenger (por defecto)`);
      console.log('═══════════════════════════════════════════════════════');
      
      return res.status(201).json({
        _id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        role: user.role,
        isAdmin: user.isAdmin || false,
        phone: user.phone,
        university: user.university,
        studentId: user.studentId,
        profilePhoto: user.profilePhoto,
        token: generateToken(user._id),
        isNewUser: true, // Indicar que es nuevo para mostrar pantalla de bienvenida
        needsPhoneNumber: true, // Indicar que falta completar el telefono
      });
    }
    
  } catch (error) {
    console.error('═══════════════════════════════════════════════════════');
    console.error(`🔴 ERROR CRITICO EN GOOGLE SIGN-IN [${timestamp}]`);
    console.error(`📝 Mensaje: ${error.message}`);
    console.error(`📋 Stack completo:`);
    console.error(error.stack);
    console.error('═══════════════════════════════════════════════════════');
    
    // Errores especificos de Firebase
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({ 
        message: 'Token expirado. Por favor, intenta de nuevo.',
        code: 'TOKEN_EXPIRED'
      });
    }
    
    if (error.code === 'auth/invalid-id-token') {
      return res.status(401).json({ 
        message: 'Token invalido. Por favor, intenta de nuevo.',
        code: 'TOKEN_INVALID'
      });
    }
    
    // Error generico
    res.status(500).json({ 
      message: `Error al autenticar con Google: ${error.message}`,
      code: 'GOOGLE_AUTH_ERROR'
    });
  }
};