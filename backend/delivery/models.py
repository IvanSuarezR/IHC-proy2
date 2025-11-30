from django.db import models

class Conductor(models.Model):
    nombre = models.CharField(max_length=100)
    activo = models.BooleanField(default=False)
    con_pedido = models.BooleanField(default=False)
    fcm_token = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return self.nombre

# Eliminamos la clase Pedido de aqui ya que usaremos la de la app 'pedidos'

class Ubicacion(models.Model):
    conductor = models.OneToOneField(Conductor, on_delete=models.CASCADE)
    coordenadas = models.CharField(max_length=100, help_text="Formato: lat,lng", null=True, blank=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Ubicación de {self.conductor.nombre}"
