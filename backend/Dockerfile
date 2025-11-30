# Usar una imagen oficial de Python
FROM python:3.11-slim

# Establecer variables de entorno
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Establecer el directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias para compilar psycopg2
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependencias
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY . /app/
COPY firebase_credentials.json /app/firebase_credentials.json

# Dar permisos de ejecución al entrypoint
RUN chmod +x /app/entrypoint.sh

# Exponer el puerto en el que correrá la aplicación
EXPOSE 8080

# Comando para ejecutar la aplicación
CMD ["/app/entrypoint.sh"]
