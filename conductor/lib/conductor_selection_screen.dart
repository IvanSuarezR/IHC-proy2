import 'dart:async';
import 'package:conductor/api_service.dart';
import 'package:conductor/order_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'location_service.dart';

class ConductorSelectionScreen extends StatefulWidget {
  const ConductorSelectionScreen({super.key});

  @override
  State<ConductorSelectionScreen> createState() => _ConductorSelectionScreenState();
}

class _ConductorSelectionScreenState extends State<ConductorSelectionScreen> {
  final ApiService apiService = ApiService();
  late Stream<List<dynamic>> _conductoresStream;
  late StreamController<List<dynamic>> _streamController;

  // Paleta de colores
  static const Color primaryRed = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _checkSavedConductor();
    _requestLocationPermission();
    _streamController = StreamController<List<dynamic>>.broadcast();
    _conductoresStream = _streamController.stream;
    _startFetchingConductores();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  void _startFetchingConductores() {
    _fetchConductores();
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchConductores();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchConductores() async {
    try {
      final conductores = await apiService.getConductores();
      if (!_streamController.isClosed) {
        _streamController.add(conductores);
      }
    } catch (e) {
      if (!_streamController.isClosed) {
        _streamController.addError(e);
      }
    }
  }

  Future<void> _checkSavedConductor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedConductorId = prefs.getInt('conductor_id');
    final savedConductorName = prefs.getString('conductor_nombre');

    if (savedConductorId != null && savedConductorName != null && mounted) {
      try {
        await apiService.activarConductor(savedConductorId);
        _navigateToOrderScreen(context, savedConductorName, savedConductorId);
      } catch (e) {
        // Si falla la reactivación, dejamos que el usuario elija de nuevo
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  Future<void> _selectConductor(int id, String nombre) async {
    try {
      String? fcmToken;
      if (kReleaseMode) {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        print('Permisos de notificación concedidos: ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          try {
            fcmToken = await FirebaseMessaging.instance.getToken();
            print('Token FCM obtenido: $fcmToken');
          } catch (e) {
            print('Error al obtener el token FCM: $e');
          }
        } else {
          print('El usuario denegó los permisos de notificación');
        }
      }
      
      await apiService.activarConductor(id, fcmToken: fcmToken);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('conductor_id', id);
      await prefs.setString('conductor_nombre', nombre);

      LocationService().init();
      
      if (mounted) {
        _navigateToOrderScreen(context, nombre, id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al activar conductor: $e')),
        );
      }
    }
  }

  void _navigateToOrderScreen(BuildContext context, String conductorName, int conductorId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreen(conductorNombre: conductorName, conductorId: conductorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        title: const Text(
          'Seleccionar Perfil de Conductor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _conductoresStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryRed));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay conductores disponibles'));
          } else {
            return ListView.separated(
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final conductor = snapshot.data![index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryRed,
                    child: Text(
                      conductor['nombre'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(conductor['nombre']),
                  subtitle: Text(conductor['activo'] ? 'Activo' : 'Inactivo'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _selectConductor(conductor['id'], conductor['nombre']),
                );
              },
            );
          }
        },
      ),
    );
  }
}