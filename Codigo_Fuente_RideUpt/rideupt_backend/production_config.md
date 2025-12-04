# 🚀 Configuración de Producción - RideUpt Backend

## 📋 Pasos para configurar el servidor en producción

### 1. Configurar Variables de Entorno

Crea un archivo `.env` en el directorio `rideupt-backend/` con el siguiente contenido:

```bash
# MongoDB Atlas (Recomendado para producción)
MONGO_URI=mongodb+srv://usuario:password@cluster.xxxxx.mongodb.net/rideupt?retryWrites=true&w=majority&appName=RideUpt

# JWT Secret (Cambia por una clave segura)
JWT_SECRET=tu_clave_secreta_muy_segura_aqui

# Puerto del servidor
PORT=3000

# Entorno
NODE_ENV=production

# Debug (opcional)
DEBUG=false
```

### 2. Configurar MongoDB Atlas

1. Ve a [MongoDB Atlas](https://cloud.mongodb.com)
2. Crea una cuenta gratuita
3. Crea un cluster gratuito (M0)
4. Configura un usuario de base de datos
5. Agrega tu IP a la whitelist (o usa `0.0.0.0/0` para permitir todas)
6. Copia la connection string y reemplaza `<password>` con tu contraseña real

### 3. Generar JWT Secret

Ejecuta este comando para generar una clave secreta segura:

```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 4. Iniciar el Servidor

```bash
# Opción 1: Con Docker (Recomendado)
docker compose -f docker-compose.prod.yml up -d

# Opción 2: Directamente con Node.js
npm install
node server.js
```

### 5. Verificar que Funcione

```bash
# Ver logs del contenedor
docker compose -f docker-compose.prod.yml logs -f api

# Verificar health check
curl http://localhost:3000/health

# Verificar estado
docker compose -f docker-compose.prod.yml ps
```

## 🔧 Comandos Útiles

```bash
# Ver logs en tiempo real
docker compose -f docker-compose.prod.yml logs -f api

# Reiniciar el servicio
docker compose -f docker-compose.prod.yml restart api

# Detener el servicio
docker compose -f docker-compose.prod.yml down

# Reconstruir la imagen
docker compose -f docker-compose.prod.yml up -d --build

# Ver estadísticas de recursos
docker stats rideupt-api-prod
```

## ⚠️ Notas Importantes

1. **NUNCA** subas el archivo `.env` con valores reales a Git
2. En producción, usa variables de entorno del servidor
3. Cambia `JWT_SECRET` por un valor único y seguro
4. Configura MongoDB Atlas para mejor rendimiento y seguridad
5. Usa HTTPS en producción para mayor seguridad

## 🆘 Solución de Problemas

### Error: "MongoDB connection error"
- Verifica que la URL de MongoDB Atlas sea correcta
- Asegúrate de que tu IP esté en la whitelist de MongoDB Atlas
- Verifica que el usuario y contraseña sean correctos

### Error: "JWT_SECRET not defined"
- Asegúrate de que la variable `JWT_SECRET` esté definida en el archivo `.env`
- Genera una nueva clave secreta segura

### Error: "Port already in use"
- Cambia el puerto en la variable `PORT` del archivo `.env`
- O detén el proceso que está usando el puerto 3000

