// routes/auth.js
const express = require('express');
const router = express.Router();
const { check } = require('express-validator');
const { register, login, googleSignIn } = require('../controllers/authController');

router.post(
  '/register',
  [
    check('firstName', 'El nombre es obligatorio').not().isEmpty(),
    check('lastName', 'El apellido es obligatorio').not().isEmpty(),
    check('email', 'Por favor, incluye un email válido').isEmail(),
    check('password', 'La contraseña debe tener 6 o más caracteres').isLength({ min: 6 }),
    check('phone', 'El teléfono es obligatorio').not().isEmpty(),
    check('university', 'La universidad es obligatoria').not().isEmpty(),
    check('studentId', 'El ID de estudiante es obligatorio').not().isEmpty(),
    check('email').custom(value => {
        const allowedDomains = ['@upt.pe', '@virtual.upt.pe'];
        const isAllowed = allowedDomains.some(domain => value.endsWith(domain));
        if (!isAllowed) {
            throw new Error('Debe usar un correo institucional de la UPT');
        }
        return true;
    })
  ],
  register
);

router.post('/login', [
    check('email', 'Email es requerido').isEmail(),
    check('password', 'Contraseña es requerida').exists()
], login);

// ==========================================
// GOOGLE SIGN-IN
// ==========================================
router.post('/google', googleSignIn);

module.exports = router;