from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Pedido
from .serializers import PedidoSerializer
from delivery.services import asignar_pedido
from delivery.models import Conductor

class PedidoViewSet(viewsets.ModelViewSet):
    queryset = Pedido.objects.all()
    serializer_class = PedidoSerializer

    def get_queryset(self):
        """
        Filtra los pedidos para mostrar solo los disponibles o asignados al conductor actual (si existiera autenticacion)
        """
        # Filtrar por telegram_id si se proporciona como query param
        telegram_id = self.request.query_params.get('telegram_id', None)
        
        if telegram_id:
            return Pedido.objects.filter(telegram_id=telegram_id).order_by('-created_at')
        
        # Retornar todos los pedidos ordenados por fecha
        return Pedido.objects.all().order_by('-created_at')

    def partial_update(self, request, *args, **kwargs):
        pedido = self.get_object()
        estado = request.data.get('estado')
        
        conductor_id = request.data.get('conductor_id')
        
        if estado == 'aceptado':
            if conductor_id:
                 # Verificar si el conductor ya tiene un pedido en curso
                pedidos_en_curso = Pedido.objects.filter(
                    conductor_id=conductor_id,
                    estado__in=['aceptado', 'recibido']
                ).exclude(id=pedido.id)

                if pedidos_en_curso.exists():
                     return Response(
                        {'error': 'Ya tienes un pedido en curso. Debes completarlo antes de aceptar otro.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Marcar al conductor como ocupado
                try:
                    conductor = Conductor.objects.get(id=conductor_id)
                    conductor.con_pedido = True
                    pedido.conductor = conductor
                    pedido.save() # Guardar el pedido con el conductor asignado
                    conductor.save()
                except Conductor.DoesNotExist:
                    pass

        if estado == 'entregado' or estado == 'cancelado':
             # Siempre intentar liberar al conductor asignado al pedido,
             # incluso si no viene conductor_id en el request (ej: cancelación por cliente)
             current_conductor = pedido.conductor
             if current_conductor:
                 current_conductor.con_pedido = False
                 current_conductor.save()
             
             # Si viene conductor_id explicito, asegurarnos tambien (redundancia por seguridad)
             if conductor_id:
                try:
                    conductor = Conductor.objects.get(id=conductor_id)
                    conductor.con_pedido = False
                    conductor.save()
                except Conductor.DoesNotExist:
                    pass

        if estado == 'rechazado':
            # Si un conductor rechaza, lo agregamos a la lista negra de este pedido y buscamos otro
            # Asumimos que request.user es el conductor (o pasamos conductor_id)
            # Como no hay auth implementada completa, simularemos que viene 'conductor_id' en el body
            if conductor_id:
                pedido.conductores_rechazados.add(conductor_id)
                pedido.conductor = None # Desasignamos
                pedido.save()
                
                # Buscamos nuevo conductor
                # La nueva lógica de asignar_pedido maneja el caso de no encontrar a nadie.
                asignar_pedido(pedido)
                
                # El estado del pedido ahora será 'buscando' (si se encontró a alguien) o 'disponible' (si no).
                # La respuesta debe informar al conductor que su rechazo fue procesado.
                return Response({'status': 'pedido rechazado, buscando nuevo conductor o marcado como disponible'}, status=status.HTTP_200_OK)
        
        return super().partial_update(request, *args, **kwargs)
