// create_admin.js
// Script para crear o actualizar un usuario como administrador
// El admin puede iniciar sesión con Google Sign-In (igual que los demás usuarios)
// Solo necesita tener isAdmin: true en la base de datos

const mongoose = require('mongoose');
require('dotenv').config();

// Importar el modelo real de User para mantener consistencia
const User = require('./models/User');

async function createAdmin() {
  try {
    // Conectar a MongoDB
    const mongoUri = process.env.MONGO_URI || 'mongodb+srv://***:***@cluster0.rvofy8k.mongodb.net/RideUpt?retryWrites=true&w=majority&appName=Cluster0';
    await mongoose.connect(mongoUri);
    console.log('✅ Conectado a MongoDB');

    const email = 'jb2017059611@virtual.upt.pe';

    console.log('🔍 Buscando usuario con email:', email);

    // Verificar si ya existe
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log('⚠️  El usuario ya existe. Actualizando a admin...');
      console.log('   📧 Email:', existingUser.email);
      console.log('   👤 Nombre actual:', existingUser.firstName, existingUser.lastName);
      console.log('   🎭 Rol actual:', existingUser.role);
      
      // Actualizar el campo isAdmin a true
      // El usuario puede iniciar sesión con Google Sign-In normalmente
      existingUser.isAdmin = true;
      
      // Actualizar otros datos si es necesario
      existingUser.firstName = 'Jorge Luis';
      existingUser.lastName = 'BRICEÑO DÍAZ';
      existingUser.university = 'UPT';
      existingUser.studentId = '2017059611';
      
      await existingUser.save();
      console.log('═══════════════════════════════════════════════════════');
      console.log('✅ Usuario actualizado a administrador exitosamente');
      console.log('   📧 Email:', existingUser.email);
      console.log('   👤 Nombre:', existingUser.firstName, existingUser.lastName);
      console.log('   🎭 Rol:', existingUser.role);
      console.log('   👑 isAdmin:', existingUser.isAdmin);
      console.log('   🔑 Inicio de sesión:');
      console.log('      - Google Sign-In: Con su cuenta de Google asociada a este email');
      console.log('      - La app verificará automáticamente si isAdmin === true');
      console.log('═══════════════════════════════════════════════════════');
    } else {
      // Si el usuario no existe, se creará automáticamente cuando haga Google Sign-In
      // Pero podemos crearlo manualmente aquí si lo prefieres
      console.log('⚠️  El usuario NO existe en la base de datos.');
      console.log('   💡 El usuario se creará automáticamente cuando haga Google Sign-In');
      console.log('   💡 O puedes ejecutar este script después de que se registre');
      console.log('');
      console.log('   Para crear el usuario manualmente, descomenta el código siguiente:');
      console.log('   (Pero es mejor dejar que se cree con Google Sign-In y luego ejecutar este script)');
      
      // Descomentar si quieres crear el usuario manualmente:
      /*
      const admin = new User({
        firstName: 'Jorge Luis',
        lastName: 'BRICEÑO DÍAZ',
        email: email,
        password: 'temp_password_will_be_replaced_by_google', // Se reemplazará cuando haga Google Sign-In
        phone: 'Pendiente',
        university: 'UPT',
        studentId: '2017059611',
        role: 'passenger', // Puede ser 'passenger' o 'driver'
        isAdmin: true, // Campo para indicar que es administrador
      });
      await admin.save();
      console.log('✅ Administrador creado manualmente');
      */
    }

    await mongoose.disconnect();
    console.log('✅ Desconectado de MongoDB');
  } catch (error) {
    console.error('═══════════════════════════════════════════════════════');
    console.error('❌ Error al crear/actualizar administrador:');
    console.error('   📝 Mensaje:', error.message);
    if (error.stack) {
      console.error('   📋 Stack:', error.stack);
    }
    console.error('═══════════════════════════════════════════════════════');
    process.exit(1);
  }
}

createAdmin();

