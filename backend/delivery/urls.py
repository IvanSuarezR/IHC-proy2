from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ConductorViewSet, UbicacionViewSet
from pedidos.views import PedidoViewSet

router = DefaultRouter()
router.register(r'conductores', ConductorViewSet)
router.register(r'ubicaciones', UbicacionViewSet)
router.register(r'pedidos', PedidoViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
