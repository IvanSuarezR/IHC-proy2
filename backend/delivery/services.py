import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
from geopy.distance import geodesic
from .models import Conductor, Ubicacion
from pedidos.models import Pedido
from restaurante.models import Restaurante
import logging

logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
import os
import json

# Function to initialize Firebase
def initialize_firebase():
    if firebase_admin._apps:
        return

    # Prioritize GitHub Secret / Environment Variable
    firebase_creds_json = os.environ.get('FIREBASE_CREDENTIALS')
    if firebase_creds_json:
        try:
            cred_dict = json.loads(firebase_creds_json)
            cred = credentials.Certificate(cred_dict)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase initialized successfully from environment variable.")
            return
        except (json.JSONDecodeError, ValueError) as e:
            logger.error(f"Error decoding FIREBASE_CREDENTIALS from environment variable: {e}")
        except Exception as e:
            logger.error(f"Error initializing Firebase from environment variable: {e}")

    # Fallback to local file for development
    cred_path_options = ['backend/firebase_credentials.json', 'firebase_credentials.json']
    for path in cred_path_options:
        if os.path.exists(path):
            try:
                cred = credentials.Certificate(path)
                firebase_admin.initialize_app(cred)
                logger.info(f"Firebase initialized successfully from local file: {path}")
                return
            except Exception as e:
                logger.error(f"Error initializing Firebase from local file {path}: {e}")
    
    logger.warning("FIREBASE_CREDENTIALS environment variable not set or local file not found. Push notifications are disabled.")

# Call initialization function
initialize_firebase()

def encontrar_conductor_mas_cercano(pedido):
    conductores_disponibles = Conductor.objects.filter(
        activo=True,
        con_pedido=False
    ).exclude(
        pedidos_rechazados=pedido
    )
    
    if not conductores_disponibles.exists():
        return None
        
    # Si solo hay un conductor disponible, es el más cercano por defecto.
    if conductores_disponibles.count() == 1:
        logger.info(f"Solo se encontró un conductor disponible: {conductores_disponibles.first().nombre}")
        return conductores_disponibles.first()

    mejor_conductor = None
    distancia_minima = float('inf')
    
    restaurante = Restaurante.objects.first()
    if not restaurante or not restaurante.coordenadas:
        logger.error("No se han configurado las coordenadas del restaurante.")
        # Fallback: sin coordenadas del restaurante, no podemos calcular.
        # Podríamos devolver el primero disponible o ninguno. Devolver el primero es más robusto.
        return conductores_disponibles.first()

    try:
        r_lat, r_lng = map(float, restaurante.coordenadas.split(','))
    except (ValueError, TypeError):
        logger.error(f"Error al parsear las coordenadas del restaurante: {restaurante.coordenadas}")
        return conductores_disponibles.first()

    conductores_con_ubicacion = []
    for c in conductores_disponibles:
        try:
            if c.ubicacion and c.ubicacion.coordenadas:
                c_lat, c_lng = map(float, c.ubicacion.coordenadas.split(','))
                distancia = geodesic((r_lat, r_lng), (c_lat, c_lng)).km
                conductores_con_ubicacion.append((c, distancia))
        except (Ubicacion.DoesNotExist, ValueError, TypeError):
            # Si el conductor no tiene ubicación o está mal formateada, lo tratamos como "muy lejos".
            # Lo añadimos con una distancia infinita para que pueda ser elegido si es el único que queda.
            conductores_con_ubicacion.append((c, float('inf')))
    
    if not conductores_con_ubicacion:
        return None

    # Ordenamos la lista de conductores por su distancia
    conductores_con_ubicacion.sort(key=lambda x: x[1])

    mejor_conductor = conductores_con_ubicacion[0][0]
    distancia = conductores_con_ubicacion[0][1]

    logger.info(f"Conductor más cercano encontrado: {mejor_conductor.nombre} a {distancia:.2f} km.")
    return mejor_conductor

def notificar_conductor(conductor, pedido):
    if not conductor.fcm_token:
        return False

    # Calcular distancia entre Restaurante y Cliente para la notificación
    distancia_msg = 'Desconocida'
    
    try:
        restaurante = Restaurante.objects.first()
        if restaurante and restaurante.coordenadas and pedido.coordenadas:
            r_lat, r_lng = map(float, restaurante.coordenadas.split(','))
            c_lat, c_lng = map(float, pedido.coordenadas.split(','))
            
            dist = geodesic((r_lat, r_lng), (c_lat, c_lng)).km
            if dist < 1:
                distancia_msg = f"{int(dist*1000)} m"
            else:
                distancia_msg = f"{dist:.2f} km"
    except Exception as e:
        logger.error(f"Error calculating notification distance: {e}")

    message = messaging.Message(
        data={
            'pedido_id': str(pedido.id),
            'cliente': pedido.first_name or 'Cliente',
            'distancia': distancia_msg,
            'total': str(pedido.total),
            'type': 'nuevo_pedido',
        },
        notification=messaging.Notification(
            title='Nuevo pedido disponible',
            body=f'Nuevo pedido de {pedido.first_name}',
        ),
        token=conductor.fcm_token,
    )
    
    try:
        response = messaging.send(message)
        logger.info(f'Successfully sent message: {response}')
        return True
    except Exception as e:
        logger.error(f'Error sending message: {e}')
        return False

def notificar_a_todos_los_conductores(pedido):
    """Notifica a todos los conductores activos y sin pedido sobre un nuevo pedido disponible para cualquiera."""
    conductores = Conductor.objects.filter(activo=True, con_pedido=False)
    logger.info(f"Notificando a {conductores.count()} conductores sobre el pedido {pedido.id} disponible para todos.")
    
    # We can't send one message to multiple tokens with the standard FCM API.
    # We must iterate and send one by one.
    # For bulk sending, Firebase Admin SDK offers `send_all` or `send_multicast`.
    # Let's use multicast for efficiency.

    if not conductores.exists():
        return
        
    tokens = [c.fcm_token for c in conductores if c.fcm_token]

    if not tokens:
        logger.warning(f"No FCM tokens found for any active drivers to notify about pedido {pedido.id}")
        return

    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title='Pedido Disponible Para Todos',
            body=f'El pedido #{pedido.id} para {pedido.first_name} no ha sido asignado y ahora está disponible.',
        ),
        data={
            'pedido_id': str(pedido.id),
            'type': 'pedido_disponible',
        },
        tokens=tokens,
    )
    
    try:
        response = messaging.send_multicast(message)
        logger.info(f'Successfully sent multicast message: {response.success_count} success, {response.failure_count} failure')
    except Exception as e:
        logger.error(f'Error sending multicast message: {e}')


def asignar_pedido(pedido):
    """
    Intenta asignar un pedido al conductor más cercano.
    Si no encuentra a nadie, lo marca como 'disponible' y notifica a todos.
    """
    conductor = encontrar_conductor_mas_cercano(pedido)
    if conductor:
        pedido.conductor = conductor
        pedido.estado = 'buscando'
        pedido.save()
        
        notificar_conductor(conductor, pedido)
        logger.info(f"Pedido {pedido.id} asignado a {conductor.nombre} para búsqueda.")
        return True
    else:
        # No se encontró un conductor cercano (o todos han rechazado)
        pedido.conductor = None
        pedido.estado = 'disponible'
        pedido.save()
        
        logger.info(f"No se encontró conductor para el pedido {pedido.id}. Marcado como 'disponible'.")
        # Notificar a todos los conductores que hay un pedido "huerfano"
        notificar_a_todos_los_conductores(pedido)
        return False