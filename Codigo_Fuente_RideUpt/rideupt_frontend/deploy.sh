#!/bin/bash

# Script para compilar y desplegar RideUPT Web
# Uso: ./deploy.sh [firebase|netlify|vercel]

echo "🚀 Iniciando despliegue de RideUPT Web..."

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Compilar para web
echo "🏗️ Compilando aplicación web..."
flutter build web --release

# Verificar que la compilación fue exitosa
if [ ! -d "build/web" ]; then
    echo "❌ Error: La compilación falló"
    exit 1
fi

echo "✅ Compilación exitosa!"

# Seleccionar método de despliegue
DEPLOY_METHOD=${1:-firebase}

case $DEPLOY_METHOD in
    firebase)
        echo "🔥 Desplegando en Firebase Hosting..."
        firebase deploy --only hosting
        ;;
    netlify)
        echo "🌐 Desplegando en Netlify..."
        cd build/web
        netlify deploy --prod --dir=.
        cd ../..
        ;;
    vercel)
        echo "▲ Desplegando en Vercel..."
        cd build/web
        vercel --prod
        cd ../..
        ;;
    *)
        echo "📦 Archivos listos en build/web/"
        echo "   Puedes subirlos manualmente a tu servidor"
        ;;
esac

echo "🎉 ¡Despliegue completado!"











