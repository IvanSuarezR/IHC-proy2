import 'package:conductor/api_service.dart';
import 'package:conductor/order_screen.dart';
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
  late Future<List<dynamic>> conductores;

  @override
  void initState() {
    super.initState();
    _checkSavedConductor();
    _requestLocationPermission();
    conductores = apiService.getConductores();
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
        // Si falla la reactivación, no hacemos nada y dejamos que el usuario elija de nuevo.
        // Podríamos mostrar un error, pero es mejor simplemente no hacer login automático.
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  Future<void> _selectConductor(int id, String nombre) async {
    try {
      // Obtener token FCM
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      
      // Activar conductor y enviar token
      await apiService.activarConductor(id, fcmToken: fcmToken);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('conductor_id', id);
      await prefs.setString('conductor_nombre', nombre);

      // Start the location service
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
        title: const Text('Seleccionar Perfil de Conductor'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: conductores,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                    child: Text(conductor['nombre'][0].toUpperCase()),
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