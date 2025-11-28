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
FROM nginx:1.21.6-alpine
COPY --from=build /app/build /usr/share/nginx/html

# Configurar Nginx para usar el puerto 8080 requerido por Cloud Run
RUN sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
