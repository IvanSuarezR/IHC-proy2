import requests
import logging
import os

logger = logging.getLogger(__name__)

# URL del bot - El bot está expuesto a través del frontend en /bot/
# En producción: https://conductor-frontend-608918105626.us-central1.run.app/bot
# En local: http://localhost:3001
BOT_URL = os.environ.get('BOT_SERVICE_URL', 'https://conductor-frontend-608918105626.us-central1.run.app/bot')

def enviar_confirmacion_pedido(pedido):
    """
    Envía una notificación al usuario via Telegram cuando se crea un pedido
    """
    try:
        productos_data = [
            {
                'nombre': prod.nombre,
                'cantidad': prod.cantidad,
                'precio': float(prod.precio)
            }
            for prod in pedido.productos.all()
        ]

        data = {
            'telegram_id': pedido.telegram_id,
            'pedido_id': pedido.id,
            'productos': productos_data,
            'total': float(pedido.total),
            'direccion': pedido.direccion,
            'estado': pedido.get_estado_display()
        }

        response = requests.post(
            f"{BOT_URL}/send-order-confirmation",
            json=data,
            timeout=5
        )
        
        if response.status_code == 200:
            logger.info(f"Confirmación enviada al usuario {pedido.telegram_id} para pedido {pedido.id}")
        else:
            logger.error(f"Error enviando confirmación: {response.text}")
            
    except Exception as e:
        logger.error(f"Error al enviar confirmación de pedido: {str(e)}")


def enviar_actualizacion_estado(pedido, mensaje_extra=None):
    """
    Envía una actualización del estado del pedido al usuario
    """
    try:
        data = {
            'telegram_id': pedido.telegram_id,
            'pedido_id': pedido.id,
            'estado': pedido.get_estado_display(),
        }
        
        if mensaje_extra:
            data['mensaje_extra'] = mensaje_extra

        response = requests.post(
            f"{BOT_URL}/send-order-update",
            json=data,
            timeout=5
        )
        
        if response.status_code == 200:
            logger.info(f"Actualización enviada al usuario {pedido.telegram_id} para pedido {pedido.id}")
        else:
            logger.error(f"Error enviando actualización: {response.text}")
            
    except Exception as e:
        logger.error(f"Error al enviar actualización de estado: {str(e)}")
