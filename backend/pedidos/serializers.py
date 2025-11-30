from rest_framework import serializers
from .models import Pedido, ProductoPedido

class ProductoPedidoSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductoPedido
        fields = ['producto_id', 'nombre', 'cantidad', 'precio']

class PedidoSerializer(serializers.ModelSerializer):
    productos = ProductoPedidoSerializer(many=True)

    class Meta:
        model = Pedido
        fields = ['id', 'telegram_id', 'first_name', 'username', 'phone_number', 'direccion', 'coordenadas', 'total', 'estado', 'productos', 'created_at', 'conductor']
        read_only_fields = ['created_at']

    def create(self, validated_data):
        productos_data = validated_data.pop('productos')
        pedido = Pedido.objects.create(**validated_data)
        for producto_data in productos_data:
            ProductoPedido.objects.create(pedido=pedido, **producto_data)
        return pedido
