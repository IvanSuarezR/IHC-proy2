import 'dart:convert';
import 'package:conductor/api_service.dart';
import 'package:conductor/conductor_selection_screen.dart';
import 'package:conductor/map_screen.dart';
import 'package:conductor/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'location_service.dart';

class OrderScreen extends StatefulWidget {
  final String conductorNombre;
  final int conductorId;

  const OrderScreen({super.key, required this.conductorNombre, required this.conductorId});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> _pedidos = [];
  bool _isLoading = true;
  bool _activo = true;
  Timer? _timer;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _loadPedidos();
    _startPolling();
    _setupFirebaseMessaging();
    _initializeLocalNotifications();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadPedidos();
    });
  }

  void _initializeLocalNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Ensure you have this icon
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users.
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel', // channel id from main.dart
                'High Importance Notifications', // channel name from main.dart
                channelDescription: 'This channel is used for important notifications.',
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: true,
              ),
            ));
      }

      // Always reload the order list
      _loadPedidos();
    });
  }

  Future<void> _loadPedidos() async {
    try {
      final pedidos = await apiService.getPedidos();
      if (mounted) {
        setState(() {
          _pedidos = pedidos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pedidos: $e')),
        );
      }
    }
  }

  // Lógica mejorada para actualizar pedido y gestionar navegación
  Future<void> _actualizarEstadoPedido(int id, String estado) async {
    // Si aceptamos, verificamos localmente si podemos (aunque el backend también restringe)
    if (estado == 'aceptado') {
      try {
        await apiService.actualizarPedido(id, estado);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido aceptado.')),
          );
          _loadPedidos(); // Recargar lista
          
          // Navegar automáticamente a detalles
           // Buscamos el pedido actualizado para pasarlo
           final updatedPedidos = await apiService.getPedidos();
           final acceptedOrder = updatedPedidos.firstWhere((p) => p['id'] == id, orElse: () => null);
           
           if (acceptedOrder != null && mounted) {
               _navigateToDetail(acceptedOrder);
           }
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')), // Mostrará el mensaje del backend si ya tiene pedido
          );
         }
      }
    } else {
        // Otros estados (rechazar, etc)
        apiService.actualizarPedido(id, estado).then((_) {
          _loadPedidos();
          if (estado == 'rechazado') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pedido rechazado. Buscando otro conductor...')),
            );
          }
        }).catchError((e) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
        });
    }
  }

  Future<void> _navigateToDetail(Map<String, dynamic> pedido) async {
    // Usamos pushReplacement si ya estamos en un flujo obligatorio, pero push normal permite volver si el pedido no esta terminado.
    // Sin embargo, si queremos bloquear la lista, lo ideal es push y en OrderDetailScreen bloquear el back.
    // Si el pedido se completa, OrderDetailScreen hace pop(true).
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(pedido: pedido),
      ),
    );
    // Si retornó true (pedido completado), recargamos la lista para ver nuevos
    if (result == true) {
      _loadPedidos();
    } else {
      // Si volvió sin completar (ej: cancelado o solo back), recargamos por si acaso
      _loadPedidos();
    }
  }

  Future<void> _logout() async {
    try {
      // Stop the location service
      LocationService().stop();
      
      await apiService.desactivarConductor(widget.conductorId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('conductor_id');
      await prefs.remove('conductor_nombre');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ConductorSelectionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al desactivar conductor: $e')),
        );
      }
    }
  }
  
  // Custom API Service call override to include conductor_id in body for "aceptado"/"rechazado" checks
  // Dart doesn't support easy monkey-patching so we extend/modify behavior here or assume apiService handles it.
  // The ApiService class provided earlier didn't take conductor_id. 
  // We need to pass conductor_id to the backend for validation.
  // Since I cannot easily modify ApiService across files without reading/writing it again, 
  // I will implement a specific update function here that includes the conductor_id.
  
  Future<void> _actualizarPedidoConConductor(int pedidoId, String estado) async {
      final url = Uri.parse('${apiService.baseUrl}/pedidos/$pedidoId/');
      
      final response = await http.patch(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'estado': estado,
          'conductor_id': widget.conductorId, // Enviamos el ID del conductor
        }),
      );

      if (response.statusCode != 200) {
        // Intentar parsear el error del backend
        try {
            final errorBody = jsonDecode(response.body);
            throw Exception(errorBody['error'] ?? 'Failed to update pedido');
        } catch (_) {
            throw Exception('Failed to update pedido');
        }
      }
  }
  
  // Sobrescribimos la llamada anterior para usar nuestra funcion con ID
  void _procesarAccionPedido(int id, String estado) {
      if (estado == 'aceptado' || estado == 'rechazado') {
           _actualizarPedidoConConductor(id, estado).then((_) async {
               if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(estado == 'aceptado' ? 'Pedido aceptado.' : 'Pedido rechazado.')),
                  );
                  _loadPedidos();

                  if (estado == 'aceptado') {
                       // Navegacion automatica
                       final updatedPedidos = await apiService.getPedidos();
                       final acceptedOrder = updatedPedidos.firstWhere((p) => p['id'] == id, orElse: () => null);
                       if (acceptedOrder != null && mounted) {
                           _navigateToDetail(acceptedOrder);
                       }
                  }
               }
           }).catchError((e) {
               if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${e.toString().replaceAll("Exception:", "")}')),
                  );
               }
           });
      } else {
          // Para otros estados (recibido, entregado) usamos la api normal o la misma
          _actualizarEstadoPedido(id, estado);
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.conductorNombre} (ID: ${widget.conductorId})'),
        leading: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cambiar Conductor',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.circle, color: _activo ? Colors.green : Colors.red, size: 12),
                const SizedBox(width: 4),
                Text(_activo ? 'Activo' : 'Inactivo', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPedidos,
              child: _buildPedidosList(),
            ),
    );
  }

  Widget _buildPedidosList() {
    if (_pedidos.isEmpty) {
      return const Center(child: Text('No hay pedidos disponibles'));
    }

    final pedidosFiltrados = _pedidos.where((p) {
      final estado = p['estado'];
      final conductorAsignado = p['conductor'];
      
      // Conductor puede ver pedidos:
      // 1. Disponibles para todos.
      // 2. Pendientes (lógica original, por si acaso).
      // 3. Que se le están buscando a ÉL específicamente.
      // 4. Que ÉL ha aceptado o tiene en curso.
      if (estado == 'disponible' || estado == 'pendiente') return true;
      if (estado == 'buscando' && conductorAsignado == widget.conductorId) return true;
      if (conductorAsignado == widget.conductorId && (estado == 'aceptado' || estado == 'recibido')) return true;

      return false;
    }).toList();

    final pedidoEnCurso = pedidosFiltrados.firstWhere(
        (p) => (p['conductor'] == widget.conductorId) && (p['estado'] == 'aceptado' || p['estado'] == 'recibido'),
        orElse: () => null
    );

    List<dynamic> listaAMostrar;
    if (pedidoEnCurso != null) {
      listaAMostrar = [pedidoEnCurso];
    } else {
      listaAMostrar = pedidosFiltrados.where((p) => p['estado'] == 'pendiente' || p['estado'] == 'buscando' || p['estado'] == 'disponible').toList();
    }

    if (listaAMostrar.isEmpty) {
      return const Center(child: Text('No hay pedidos activos para ti'));
    }

    return ListView.builder(
      itemCount: listaAMostrar.length,
      itemBuilder: (context, index) {
        final pedido = listaAMostrar[index];
        final esMio = pedido['conductor'] == widget.conductorId;
        
        return Card(
          margin: const EdgeInsets.all(8.0),
          color: esMio ? Colors.blue.shade50 : null,
          child: Column(
            children: [
              ListTile(
                title: Text('Pedido #${pedido['id']} - ${pedido['first_name']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dirección: ${pedido['direccion']}'),
                    Text('Total: ${pedido['total']} Bs'),
                     if (pedido['estado'] == 'aceptado') ...[
                        const Text('Estado: ACEPTADO - Ve al restaurante', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                     ],
                     if (pedido['estado'] == 'recibido') ...[
                        const Text('Estado: EN RUTA - Ve al cliente', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                     ],
                    const SizedBox(height: 8),
                    const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...(pedido['productos'] as List).map((p) => Text('- ${p['cantidad']}x ${p['nombre']}')),
                  ],
                ),
                isThreeLine: true,
                onTap: esMio ? () => _navigateToDetail(pedido) : null,
              ),
              ButtonBar(
                children: [
                  if (pedido['estado'] == 'buscando' || pedido['estado'] == 'pendiente' || pedido['estado'] == 'disponible') ...[
                    if (pedido['estado'] == 'disponible')
                      Chip(label: Text('DISPONIBLE PARA TODOS'), backgroundColor: Colors.amber.shade100),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text('ACEPTAR', style: TextStyle(color: Colors.green)),
                      onPressed: () => _procesarAccionPedido(pedido['id'], 'aceptado'),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('RECHAZAR', style: TextStyle(color: Colors.red)),
                      onPressed: () => _procesarAccionPedido(pedido['id'], 'rechazado'),
                    ),
                  ] else if (esMio) ...[
                     ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('VER DETALLES Y GESTIONAR'),
                      onPressed: () => _navigateToDetail(pedido),
                    ),
                  ],
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
