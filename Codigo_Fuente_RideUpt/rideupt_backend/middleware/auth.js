// middleware/auth.js
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  console.log(`🔐 [Auth] Verificando autenticación para: ${req.method} ${req.path}`);
  console.log(`🔐 [Auth] Headers authorization: ${req.headers.authorization ? 'Presente' : 'Ausente'}`);

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Obtener el token del header
      token = req.headers.authorization.split(' ')[1];
      console.log(`🔐 [Auth] Token extraído: ${token ? 'SÍ' : 'NO'}`);

      // Verificar el token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      console.log(`🔐 [Auth] Token válido, ID usuario: ${decoded.id}`);

      // Obtener el usuario del token y adjuntarlo al objeto 'req'
      req.user = await User.findById(decoded.id).select('-password');
      
      if (!req.user) {
          console.error(`❌ [Auth] Usuario no encontrado con ID: ${decoded.id}`);
          return res.status(401).json({ message: 'No autorizado, usuario no encontrado' });
      }

      console.log(`✅ [Auth] Usuario autenticado: ${req.user.email}`);
      next();
    } catch (error) {
      console.error(`❌ [Auth] Error al verificar token: ${error.message}`);
      return res.status(401).json({ message: 'No autorizado, token inválido' });
    }
  }

  if (!token) {
    console.error(`❌ [Auth] No se proporcionó token`);
    return res.status(401).json({ message: 'No autorizado, no se proporcionó un token' });
  }
};

const isDriver = (req, res, next) => {
    if (req.user && req.user.role === 'driver') {
        next();
    } else {
        res.status(403).json({ message: 'Acceso denegado. Solo conductores.' });
    }
};

module.exports = { protect, isDriver };