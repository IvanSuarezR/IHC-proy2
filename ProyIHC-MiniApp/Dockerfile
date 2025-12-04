# Etapa de construcción
FROM node:16-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Aceptar argumentos de construcción
ARG _REACT_APP_API_URL
ARG _REACT_APP_GOOGLE_MAPS_KEY

# Establecer variables de entorno para el build
ENV REACT_APP_API_URL=$_REACT_APP_API_URL
ENV REACT_APP_GOOGLE_MAPS_KEY=$_REACT_APP_GOOGLE_MAPS_KEY

RUN npm run build

# Etapa de producción
FROM node:16-alpine

# Instalar nginx
RUN apk add --no-cache nginx

# Copiar el build de React
COPY --from=build /app/build /usr/share/nginx/html

# Copiar los archivos del bot y dependencias
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY Bot ./Bot
COPY src/images ./src/images

# Configurar Nginx para usar el puerto 8080
RUN mkdir -p /run/nginx /var/log/nginx && \
    rm -f /etc/nginx/http.d/default.conf && \
    echo 'server {' > /etc/nginx/http.d/default.conf && \
    echo '    listen 8080;' >> /etc/nginx/http.d/default.conf && \
    echo '    server_name _;' >> /etc/nginx/http.d/default.conf && \
    echo '    root /usr/share/nginx/html;' >> /etc/nginx/http.d/default.conf && \
    echo '    index index.html;' >> /etc/nginx/http.d/default.conf && \
    echo '    location / {' >> /etc/nginx/http.d/default.conf && \
    echo '        try_files $uri $uri/ /index.html;' >> /etc/nginx/http.d/default.conf && \
    echo '    }' >> /etc/nginx/http.d/default.conf && \
    echo '}' >> /etc/nginx/http.d/default.conf

# Crear script de inicio que ejecute el bot en segundo plano y luego Nginx
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo 'echo "Iniciando bot de Telegram..."' >> /start.sh && \
    echo 'cd /app && node Bot/bot.js > /tmp/bot.log 2>&1 &' >> /start.sh && \
    echo 'echo "Bot iniciado en segundo plano"' >> /start.sh && \
    echo 'echo "Iniciando Nginx en puerto 8080..."' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
