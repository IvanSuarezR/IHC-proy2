from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Conductor, Ubicacion
from .serializers import ConductorSerializer, UbicacionSerializer

class ConductorViewSet(viewsets.ModelViewSet):
    queryset = Conductor.objects.all()
    serializer_class = ConductorSerializer

    @action(detail=True, methods=['post'])
    def activar(self, request, pk=None):
        conductor = self.get_object()
        fcm_token = request.data.get('fcm_token')

        conductor.activo = True
        if fcm_token:
            conductor.fcm_token = fcm_token
        
        conductor.save()
        return Response({'status': 'conductor activado', 'activo': True, 'fcm_token': conductor.fcm_token})

    @action(detail=True, methods=['post'])
    def desactivar(self, request, pk=None):
        conductor = self.get_object()
        conductor.activo = False
        conductor.save()
        return Response({'status': 'conductor desactivado', 'activo': False})

class ConductorActivoViewSet(viewsets.ReadOnlyModelViewSet):
    """
    A viewset that only returns active conductors.
    """
    queryset = Conductor.objects.filter(activo=True)
    serializer_class = ConductorSerializer

class UbicacionViewSet(viewsets.ModelViewSet):
    queryset = Ubicacion.objects.all()
    serializer_class = UbicacionSerializer

    def create(self, request, *args, **kwargs):
        conductor_id = request.data.get('conductor')
        coordenadas = request.data.get('coordenadas')

        if not conductor_id or not coordenadas:
            return Response(
                {'error': 'conductor and coordenadas are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            conductor = Conductor.objects.get(id=conductor_id)
        except Conductor.DoesNotExist:
            return Response(
                {'error': f'Conductor with id {conductor_id} does not exist.'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Update or create the location
        ubicacion, created = Ubicacion.objects.update_or_create(
            conductor=conductor,
            defaults={'coordenadas': coordenadas}
        )

        serializer = self.get_serializer(ubicacion)
        headers = self.get_success_headers(serializer.data)
        
        # Return 201 if created, 200 if updated
        if created:
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        else:
            return Response(serializer.data, status=status.HTTP_200_OK, headers=headers)
