@echo off
echo 🚀 Configurando RideUpt Backend para Producción
echo ==============================================

REM Crear archivo .env si no existe
if not exist .env (
    echo 📝 Creando archivo .env...
    (
        echo # Configuración de producción para RideUpt Backend
        echo MONGO_URI=mongodb+srv://usuario:password@cluster.xxxxx.mongodb.net/rideupt?retryWrites=true^&w=majority^&appName=RideUpt
        echo JWT_SECRET=tu_clave_secreta_muy_segura_aqui
        echo PORT=3000
        echo NODE_ENV=production
        echo DEBUG=false
    ) > .env
    echo ✅ Archivo .env creado
    echo ⚠️  IMPORTANTE: Edita el archivo .env con tus valores reales
) else (
    echo ✅ Archivo .env ya existe
)

REM Instalar dependencias
echo 📦 Instalando dependencias...
npm install

echo ✅ Configuración completada
echo.
echo 📋 Próximos pasos:
echo 1. Edita el archivo .env con tus valores reales
echo 2. Configura MongoDB Atlas o tu base de datos
echo 3. Ejecuta: docker compose -f docker-compose.prod.yml up -d
echo.
echo 🔧 Para configurar MongoDB Atlas:
echo 1. Ve a https://cloud.mongodb.com
echo 2. Crea un cluster gratuito
echo 3. Configura un usuario de base de datos
echo 4. Agrega tu IP a la whitelist
echo 5. Copia la connection string al archivo .env
pause

