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
        logger.info(f"Intentando enviar confirmación para pedido {pedido.id} a usuario {pedido.telegram_id}")
        
        productos_data = [
            {
                'nombre': prod.nombre,
                'cantidad': prod.cantidad,
                'precio': float(prod.precio)
            }
            for prod in pedido.productos.all()
        ]

        data = {
            'telegram_id': str(pedido.telegram_id),
            'pedido_id': pedido.id,
            'productos': productos_data,
            'total': float(pedido.total),
            'direccion': pedido.direccion,
            'estado': pedido.get_estado_display()
        }
        
        logger.info(f"URL del bot: {BOT_URL}/send-order-confirmation")
        logger.info(f"Datos a enviar: {data}")

        response = requests.post(
            f"{BOT_URL}/send-order-confirmation",
            json=data,
            timeout=10
        )
        
        logger.info(f"Respuesta del bot: Status {response.status_code}, Body: {response.text}")
        
        if response.status_code == 200:
            logger.info(f"✅ Confirmación enviada exitosamente al usuario {pedido.telegram_id} para pedido {pedido.id}")
        else:
            logger.error(f"❌ Error enviando confirmación (status {response.status_code}): {response.text}")
            
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Error de conexión al enviar confirmación: {str(e)}")
    except Exception as e:
        logger.error(f"❌ Error inesperado al enviar confirmación de pedido: {str(e)}", exc_info=True)


def enviar_actualizacion_estado(pedido, mensaje_extra=None):
    """
    Envía una actualización del estado del pedido al usuario
    """
    try:
        logger.info(f"Intentando enviar actualización de estado para pedido {pedido.id} (estado: {pedido.estado})")
        
        data = {
            'telegram_id': str(pedido.telegram_id),
            'pedido_id': pedido.id,
            'estado': pedido.get_estado_display(),
        }
        
        if mensaje_extra:
            data['mensaje_extra'] = mensaje_extra
        
        logger.info(f"URL del bot: {BOT_URL}/send-order-update")
        logger.info(f"Datos a enviar: {data}")

        response = requests.post(
            f"{BOT_URL}/send-order-update",
            json=data,
            timeout=10
        )
        
        logger.info(f"Respuesta del bot: Status {response.status_code}, Body: {response.text}")
        
        if response.status_code == 200:
            logger.info(f"✅ Actualización enviada exitosamente al usuario {pedido.telegram_id} para pedido {pedido.id}")
        else:
            logger.error(f"❌ Error enviando actualización (status {response.status_code}): {response.text}")
            
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Error de conexión al enviar actualización: {str(e)}")
    except Exception as e:
        logger.error(f"❌ Error inesperado al enviar actualización de estado: {str(e)}", exc_info=True)
