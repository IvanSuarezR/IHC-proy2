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
RUN mkdir -p /run/nginx && \
    sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/http.d/default.conf || \
    echo 'server { listen 8080; root /usr/share/nginx/html; index index.html; location / { try_files $uri $uri/ /index.html; } }' > /etc/nginx/http.d/default.conf

# Crear script de inicio que ejecute Nginx y el bot
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'nginx' >> /start.sh && \
    echo 'cd /app && node Bot/bot.js' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
