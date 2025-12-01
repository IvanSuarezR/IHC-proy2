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

    @action(detail=False, methods=['get'])
    def activos(self, request):
        """
        Devuelve una lista de todos los conductores activos.
        """
        conductores = self.get_queryset().filter(activo=True)
        serializer = self.get_serializer(conductores, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def actualizar_ubicacion(self, request, pk=None):
        conductor = self.get_object()
        coordenadas = request.data.get('coordenadas')

        if not coordenadas:
            return Response(
                {'error': 'coordenadas are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        ubicacion, created = Ubicacion.objects.update_or_create(
            conductor=conductor,
            defaults={'coordenadas': coordenadas}
        )
        
        status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(UbicacionSerializer(ubicacion).data, status=status_code)

class UbicacionViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para ver ubicaciones. La creación/actualización se maneja
    a través de la acción en ConductorViewSet.
    """
    queryset = Ubicacion.objects.all()
    serializer_class = UbicacionSerializer
