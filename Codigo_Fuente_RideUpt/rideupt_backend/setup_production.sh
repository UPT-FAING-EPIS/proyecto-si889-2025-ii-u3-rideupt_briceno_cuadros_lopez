#!/bin/bash

echo "🚀 Configurando RideUpt Backend para Producción"
echo "=============================================="

# Crear archivo .env si no existe
if [ ! -f .env ]; then
    echo "📝 Creando archivo .env..."
    cat > .env << EOF
# Configuración de producción para RideUpt Backend
MONGO_URI=mongodb+srv://usuario:password@cluster.xxxxx.mongodb.net/rideupt?retryWrites=true&w=majority&appName=RideUpt
JWT_SECRET=tu_clave_secreta_muy_segura_aqui
PORT=3000
NODE_ENV=production
DEBUG=false
EOF
    echo "✅ Archivo .env creado"
    echo "⚠️  IMPORTANTE: Edita el archivo .env con tus valores reales"
else
    echo "✅ Archivo .env ya existe"
fi

# Instalar dependencias
echo "📦 Instalando dependencias..."
npm install

echo "✅ Configuración completada"
echo ""
echo "📋 Próximos pasos:"
echo "1. Edita el archivo .env con tus valores reales"
echo "2. Configura MongoDB Atlas o tu base de datos"
echo "3. Ejecuta: docker compose -f docker-compose.prod.yml up -d"
echo ""
echo "🔧 Para configurar MongoDB Atlas:"
echo "1. Ve a https://cloud.mongodb.com"
echo "2. Crea un cluster gratuito"
echo "3. Configura un usuario de base de datos"
echo "4. Agrega tu IP a la whitelist"
echo "5. Copia la connection string al archivo .env"

