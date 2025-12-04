#!/bin/bash

# ============================================
# SCRIPT DE INSTALACIÓN HTTPS PARA RIDEUPT
# ============================================
# Este script automatiza la configuración de HTTPS
# usando Nginx y Let's Encrypt
# ============================================

set -e  # Salir si hay algún error

echo "============================================"
echo "🚀 Configuración HTTPS para RideUPT Backend"
echo "============================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que se ejecute como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Por favor ejecuta este script como root o con sudo${NC}"
    exit 1
fi

# Solicitar dominio o IP
echo -e "${YELLOW}¿Tienes un dominio configurado? (s/n)${NC}"
read -r HAS_DOMAIN

if [ "$HAS_DOMAIN" = "s" ] || [ "$HAS_DOMAIN" = "S" ]; then
    echo -e "${YELLOW}Ingresa tu dominio (ej: rideupt.sytes.net):${NC}"
    read -r DOMAIN
    # Si no se ingresa nada, usar el dominio por defecto
    if [ -z "$DOMAIN" ]; then
        DOMAIN="rideupt.sytes.net"
        echo -e "${GREEN}Usando dominio por defecto: $DOMAIN${NC}"
    fi
    SERVER_NAME="$DOMAIN"
else
    echo -e "${YELLOW}Usando IP directamente: 161.132.50.113${NC}"
    SERVER_NAME="161.132.50.113"
fi

echo ""
echo -e "${GREEN}📦 Instalando Nginx y Certbot...${NC}"
apt update
apt install -y nginx certbot python3-certbot-nginx

echo ""
echo -e "${GREEN}📝 Creando configuración de Nginx...${NC}"

# Crear archivo de configuración
cat > /etc/nginx/sites-available/rideupt-backend <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;
    
    # Redirigir HTTP a HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $SERVER_NAME;
    
    # Certificados SSL (se generan con certbot)
    ssl_certificate /etc/letsencrypt/live/$SERVER_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$SERVER_NAME/privkey.pem;
    
    # Configuración SSL moderna
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de seguridad
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Tamaño máximo de archivos
    client_max_body_size 10M;
    
    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    
    # Proxy para API REST
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Proxy para Socket.IO
    location /socket.io {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
    }
    
    # Archivos estáticos
    location /storage {
        alias /var/rideupt/storage;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Habilitar el sitio
echo -e "${GREEN}🔗 Habilitando sitio de Nginx...${NC}"
ln -sf /etc/nginx/sites-available/rideupt-backend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Verificar configuración
echo -e "${GREEN}✅ Verificando configuración de Nginx...${NC}"
if nginx -t; then
    echo -e "${GREEN}✅ Configuración válida${NC}"
else
    echo -e "${RED}❌ Error en la configuración de Nginx${NC}"
    exit 1
fi

# Recargar Nginx
systemctl reload nginx

# Obtener certificado SSL
echo ""
if [ "$HAS_DOMAIN" = "s" ] || [ "$HAS_DOMAIN" = "S" ]; then
    echo -e "${GREEN}🔐 Obteniendo certificado SSL de Let's Encrypt...${NC}"
    echo -e "${YELLOW}Nota: Asegúrate de que el dominio apunte a esta IP antes de continuar${NC}"
    echo -e "${YELLOW}Presiona Enter cuando estés listo...${NC}"
    read -r
    
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@rideupt.com || {
        echo -e "${YELLOW}⚠️  No se pudo obtener certificado automáticamente${NC}"
        echo -e "${YELLOW}Intentando modo standalone...${NC}"
        systemctl stop nginx
        certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --email admin@rideupt.com || {
            echo -e "${RED}❌ Error al obtener certificado SSL${NC}"
            echo -e "${YELLOW}Verifica que el dominio apunte a esta IP y que el puerto 80 esté abierto${NC}"
            systemctl start nginx
            exit 1
        }
        systemctl start nginx
    }
else
    echo -e "${YELLOW}⚠️  Sin dominio, usando certificado autofirmado${NC}"
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/rideupt-key.pem \
        -out /etc/nginx/ssl/rideupt-cert.pem \
        -subj "/C=PE/ST=Tacna/L=Tacna/O=RideUPT/CN=161.132.50.113"
    
    # Actualizar configuración para usar certificado autofirmado
    sed -i 's|ssl_certificate /etc/letsencrypt/live/.*/fullchain.pem;|ssl_certificate /etc/nginx/ssl/rideupt-cert.pem;|' /etc/nginx/sites-available/rideupt-backend
    sed -i 's|ssl_certificate_key /etc/letsencrypt/live/.*/privkey.pem;|ssl_certificate_key /etc/nginx/ssl/rideupt-key.pem;|' /etc/nginx/sites-available/rideupt-backend
    
    nginx -t && systemctl reload nginx
fi

# Configurar firewall
echo ""
echo -e "${GREEN}🔥 Configurando firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo -e "${GREEN}✅ Puertos 80 y 443 abiertos${NC}"
else
    echo -e "${YELLOW}⚠️  UFW no está instalado, configura el firewall manualmente${NC}"
fi

# Verificar renovación automática
if [ "$HAS_DOMAIN" = "s" ] || [ "$HAS_DOMAIN" = "S" ]; then
    echo ""
    echo -e "${GREEN}🔄 Verificando renovación automática de certificados...${NC}"
    certbot renew --dry-run
    systemctl enable certbot.timer
fi

# Verificar que el backend esté corriendo
echo ""
echo -e "${GREEN}🔍 Verificando que el backend esté corriendo...${NC}"
if curl -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✅ Backend está corriendo en localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠️  El backend no responde en localhost:3000${NC}"
    echo -e "${YELLOW}Asegúrate de que el backend esté corriendo${NC}"
fi

# Resumen
echo ""
echo "============================================"
echo -e "${GREEN}✅ Configuración HTTPS completada!${NC}"
echo "============================================"
echo ""
echo "📋 Resumen:"
echo "  - Nginx configurado como reverse proxy"
echo "  - SSL/TLS habilitado"
echo "  - Backend accesible en: https://$SERVER_NAME"
echo ""
echo "🧪 Pruebas:"
echo "  curl https://$SERVER_NAME/health"
echo "  curl https://$SERVER_NAME/api/auth/google"
echo ""
echo "📝 Próximos pasos:"
echo "  1. Actualiza AppConfig en Flutter para usar HTTPS"
echo "  2. Cambia _serverPort a '443'"
echo "  3. Cambia _useHttps a true"
echo "  4. Recompila y despliega la app web"
echo ""
echo -e "${GREEN}🎉 ¡Listo!${NC}"

