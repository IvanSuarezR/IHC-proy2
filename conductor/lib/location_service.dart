import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Assuming your ApiService is in this file

// This "Headless Task" is run when the app is terminated.
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately call finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');
  // Do your work here...
  await _updateLocation(taskId);
}

Future<void> _updateLocation(String taskId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final conductorId = prefs.getInt('conductor_id');

    if (conductorId != null) {
      print('[LocationService] Updating location for conductor ID: $conductorId');
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String coordinates = '${position.latitude},${position.longitude}';

      // Use your existing ApiService to update the backend
      final apiService = ApiService();
      await apiService.actualizarUbicacion(conductorId, coordinates);
      print('[LocationService] Location updated successfully: $coordinates');
    } else {
      print('[LocationService] No conductor ID found, skipping location update.');
    }
  } catch (e) {
    print('[LocationService] Error updating location: $e');
  } finally {
    if (taskId.isNotEmpty) {
      BackgroundFetch.finish(taskId);
    }
  }
}


class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _foregroundTimer;

  Future<void> init() async {
    // Inicia el timer para actualizaciones en primer plano
    _startForegroundUpdates();

    // Configure BackgroundFetch.
    try {
      int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15, // <-- fetch interval in minutes
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiredNetworkType: NetworkType.ANY,
        ),
        _updateLocation,
        (String taskId) async { // <-- Task timeout callback
          // This task has exceeded its allowed running-time.
          // You must stop what you're doing and immediately call finish(taskId)
          print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
          BackgroundFetch.finish(taskId);
        },
      );
      print('[BackgroundFetch] configure success: $status');
    } catch(e) {
      print("[BackgroundFetch] configure ERROR: $e");
    }
  }

  Future<void> stop() async {
    _foregroundTimer?.cancel();
    BackgroundFetch.stop();
    print('[LocationService] Foreground and background updates stopped.');
  }

  void _startForegroundUpdates() {
    // Cancelar cualquier timer anterior para evitar duplicados
    _foregroundTimer?.cancel();
    
    // Ejecutamos una vez inmediatamente
    _updateLocation('');

    // Y luego cada 30 segundos
    _foregroundTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print('[LocationService] Foreground timer tick.');
      _updateLocation(''); // Pasamos un taskId vacío para el foreground
    });
  }
}