// Script para verificar el estado del servidor
const http = require('http');

console.log('🔍 Verificando estado del servidor...\n');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api',
  method: 'GET',
  timeout: 5000
};

const req = http.request(options, (res) => {
  console.log('✅ Servidor está CORRIENDO');
  console.log(`   Estado: ${res.statusCode}`);
  console.log(`   Puerto: 3000`);
  console.log(`   URL: http://localhost:3000/api`);
  console.log('\n🎉 El backend está funcionando correctamente!\n');
  process.exit(0);
});

req.on('timeout', () => {
  console.log('⏱️  Timeout - El servidor no respondió en 5 segundos');
  console.log('❌ El servidor NO está corriendo o está muy lento\n');
  process.exit(1);
});

req.on('error', (err) => {
  if (err.code === 'ECONNREFUSED') {
    console.log('❌ SERVIDOR NO ESTÁ CORRIENDO');
    console.log('   El puerto 3000 no está aceptando conexiones');
    console.log('\n💡 Solución:');
    console.log('   1. Abre una terminal en la carpeta rideupt-backend');
    console.log('   2. Ejecuta: npm start');
    console.log('   3. Verifica que veas el mensaje "Servidor corriendo en el puerto 3000"\n');
  } else {
    console.log(`❌ Error: ${err.message}`);
  }
  process.exit(1);
});

req.end();


