from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ConductorViewSet, PedidoViewSet, UbicacionViewSet

router = DefaultRouter()
router.register(r'conductores', ConductorViewSet)
router.register(r'pedidos', PedidoViewSet)
router.register(r'ubicaciones', UbicacionViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
