from django.db import models

class Pedido(models.Model):
    ESTADOS = (
        ('pendiente', 'Pendiente'),
        ('buscando', 'Buscando Conductor'),
        ('aceptado', 'Aceptado'),
        ('recibido', 'Recibido por Conductor'),
        ('entregado', 'Entregado'),
        ('cancelado', 'Cancelado'),
        ('disponible', 'Disponible para todos'),
    )

    telegram_id = models.CharField(max_length=100)
    first_name = models.CharField(max_length=100, blank=True, null=True)
    username = models.CharField(max_length=100, blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    
    direccion = models.CharField(max_length=255)
    coordenadas = models.CharField(max_length=100, blank=True, null=True, help_text="Formato: lat,lng")
    
    total = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
    
    estado = models.CharField(max_length=25, choices=ESTADOS, default='pendiente')
    conductor = models.ForeignKey('delivery.Conductor', on_delete=models.SET_NULL, null=True, blank=True, related_name='pedidos_asignados')
    conductores_rechazados = models.ManyToManyField('delivery.Conductor', blank=True, related_name='pedidos_rechazados')

    def __str__(self):
        return f"Pedido {self.id} - {self.telegram_id} ({self.estado})"

class ProductoPedido(models.Model):
    pedido = models.ForeignKey(Pedido, related_name='productos', on_delete=models.CASCADE)
    producto_id = models.IntegerField()
    nombre = models.CharField(max_length=255)
    cantidad = models.IntegerField()
    precio = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"{self.cantidad} x {self.nombre}"
