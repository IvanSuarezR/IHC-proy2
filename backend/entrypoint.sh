#!/bin/sh

# Ejecutar migraciones
echo "Running migrations..."
python manage.py migrate --noinput

# Iniciar servidor
echo "Starting server..."
exec gunicorn --bind 0.0.0.0:8080 backend.wsgi:application