from django.core.management.base import BaseCommand
from delivery.models import Conductor
import firebase_admin
from firebase_admin import credentials, messaging
import logging
import os

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Sends a test push notification to all active conductors with an FCM token.'

    def handle(self, *args, **options):
        # --- Firebase Initialization (Copied from services.py for standalone script) ---
        if not firebase_admin._apps:
            try:
                firebase_creds = os.environ.get('FIREBASE_CREDENTIALS')
                if firebase_creds:
                    if firebase_creds.startswith('{'):
                        import json
                        cred_dict = json.loads(firebase_creds)
                        cred = credentials.Certificate(cred_dict)
                    else:
                        cred = credentials.Certificate(firebase_creds)
                    firebase_admin.initialize_app(cred)
                    logger.info("Firebase initialized with environment variable.")
                elif os.path.exists('backend/firebase_credentials.json'):
                    cred = credentials.Certificate('backend/firebase_credentials.json')
                    firebase_admin.initialize_app(cred)
                    logger.info("Firebase initialized with local file (backend/).")
                elif os.path.exists('firebase_credentials.json'):
                    cred = credentials.Certificate('firebase_credentials.json')
                    firebase_admin.initialize_app(cred)
                    logger.info("Firebase initialized with local file (root).")
                else:
                    self.stdout.write(self.style.ERROR("Firebase credentials not found. Cannot send notifications."))
                    return
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error initializing Firebase: {e}"))
                return
        # --- End Firebase Initialization ---

        self.stdout.write("Searching for active conductors with FCM tokens...")
        
        active_conductors = Conductor.objects.filter(activo=True, fcm_token__isnull=False).exclude(fcm_token__exact='')

        if not active_conductors.exists():
            self.stdout.write(self.style.WARNING("No active conductors with FCM tokens found."))
            return

        self.stdout.write(f"Found {active_conductors.count()} conductor(s) to notify.")

        for conductor in active_conductors:
            self.stdout.write(f"Sending notification to {conductor.nombre} (Token: ...{conductor.fcm_token[-10:]})")
            
            message = messaging.Message(
                notification=messaging.Notification(
                    title='Prueba de Notificación',
                    body=f'Hola {conductor.nombre}, ¡esto es una prueba desde el backend!',
                ),
                data={
                    'type': 'test_notification',
                    'conductor_id': str(conductor.id)
                },
                token=conductor.fcm_token,
            )

            try:
                response = messaging.send(message)
                self.stdout.write(self.style.SUCCESS(f'Successfully sent message to {conductor.nombre}: {response}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Error sending message to {conductor.nombre}: {e}'))

        self.stdout.write(self.style.SUCCESS("Test notification process finished."))