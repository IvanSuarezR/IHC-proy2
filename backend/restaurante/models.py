from django.db import models

class Restaurante(models.Model):
    nombre = models.CharField(max_length=100)
    coordenadas = models.CharField(max_length=100, help_text="Formato: lat,lng")

    def __str__(self):
        return self.nombre
