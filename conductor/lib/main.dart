import 'package:conductor/api_service.dart';
import 'package:conductor/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conductor App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ProfileSelectionScreen(),
    );
  }
}

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  final ApiService apiService = ApiService();
  late Future<List<dynamic>> conductores;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    conductores = apiService.getConductores();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  void _navigateToOrderScreen(BuildContext context, String conductor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreen(conductor: conductor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Perfil'),
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
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ElevatedButton(
                  onPressed: () => _navigateToOrderScreen(context, snapshot.data![index]['nombre']),
                  child: Text(snapshot.data![index]['nombre']),
                );
              },
            );
          }
        },
      ),
    );
  }
}
