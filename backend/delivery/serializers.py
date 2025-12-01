from rest_framework import serializers
from .models import Conductor, Ubicacion

class UbicacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ubicacion
        fields = ['coordenadas', 'fecha_actualizacion']

class ConductorSerializer(serializers.ModelSerializer):
    # 'ubicacion' es el related_name inverso de la OneToOneField en el modelo Ubicacion
    ubicacion = UbicacionSerializer(read_only=True)

    class Meta:
        model = Conductor
        fields = ['id', 'nombre', 'activo', 'con_pedido', 'ubicacion']

class UbicacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ubicacion
        fields = '__all__'
