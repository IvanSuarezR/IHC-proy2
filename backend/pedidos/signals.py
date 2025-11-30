from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Pedido
from delivery.services import asignar_pedido

@receiver(post_save, sender=Pedido)
def pedido_creado(sender, instance, created, **kwargs):
    if created and instance.estado == 'pendiente':
        # Ejecutar la búsqueda de conductor de forma asíncrona sería ideal (Celery), 
        # pero por simplicidad lo hacemos directo aquí
        asignar_pedido(instance)