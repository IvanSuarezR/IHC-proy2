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

  // Paleta de colores
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color accentYellow = Color(0xFFFFC107);
  static const Color lightYellow = Color(0xFFFFF9C4);
  static const Color darkRed = Color(0xFFB71C1C);

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
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                channelDescription: 'This channel is used for important notifications.',
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: true,
              ),
            ));
      }
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

  Future<void> _actualizarEstadoPedido(int id, String estado) async {
    if (estado == 'aceptado') {
      try {
        await apiService.actualizarPedido(id, estado);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido aceptado.')),
          );
          _loadPedidos();
          
           final updatedPedidos = await apiService.getPedidos();
           final acceptedOrder = updatedPedidos.firstWhere((p) => p['id'] == id, orElse: () => null);
           
           if (acceptedOrder != null && mounted) {
               _navigateToDetail(acceptedOrder);
           }
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
         }
      }
    } else {
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(pedido: pedido),
      ),
    );
    if (result == true) {
      _loadPedidos();
    } else {
      _loadPedidos();
    }
  }

  Future<void> _logout() async {
    try {
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
  
  Future<void> _actualizarPedidoConConductor(int pedidoId, String estado) async {
      final url = Uri.parse('${apiService.baseUrl}/pedidos/$pedidoId/');
      
      final response = await http.patch(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'estado': estado,
          'conductor_id': widget.conductorId,
        }),
      );

      if (response.statusCode != 200) {
        try {
            final errorBody = jsonDecode(response.body);
            throw Exception(errorBody['error'] ?? 'Failed to update pedido');
        } catch (_) {
            throw Exception('Failed to update pedido');
        }
      }
  }
  
  void _procesarAccionPedido(int id, String estado) {
      if (estado == 'aceptado' || estado == 'rechazado') {
           _actualizarPedidoConConductor(id, estado).then((_) async {
               if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(estado == 'aceptado' ? 'Pedido aceptado.' : 'Pedido rechazado.')),
                  );
                  _loadPedidos();

                  if (estado == 'aceptado') {
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
          _actualizarEstadoPedido(id, estado);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conductorNombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${widget.conductorId}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        leading: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Cambiar Conductor',
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _activo ? Colors.green : Colors.red[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.white, size: 10),
                const SizedBox(width: 6),
                Text(
                  _activo ? 'Activo' : 'Inactivo',
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
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
          ? const Center(child: CircularProgressIndicator(color: primaryRed))
          : RefreshIndicator(
              color: primaryRed,
              onRefresh: _loadPedidos,
              child: _buildPedidosList(),
            ),
    );
  }

  Widget _buildPedidosList() {
    if (_pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay pedidos disponibles',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final pedidosFiltrados = _pedidos.where((p) {
      final estado = p['estado'];
      final conductorAsignado = p['conductor'];
      
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay pedidos activos para ti',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: listaAMostrar.length,
      itemBuilder: (context, index) {
        final pedido = listaAMostrar[index];
        final esMio = pedido['conductor'] == widget.conductorId;
        final estado = pedido['estado'];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: esMio ? () => _navigateToDetail(pedido) : null,
              child: Column(
                children: [
                  // Header del pedido
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: esMio ? primaryRed.withOpacity(0.1) : lightYellow,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: esMio ? primaryRed : accentYellow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            esMio ? Icons.directions_bike : Icons.receipt_long,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedido #${pedido['id']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: esMio ? primaryRed : darkRed,
                                ),
                              ),
                              Text(
                                pedido['first_name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (estado == 'disponible')
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: accentYellow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'DISPONIBLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: darkRed,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Body del pedido
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dirección
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, size: 20, color: primaryRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pedido['direccion'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Total
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.payments, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Total a cobrar:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${pedido['total']} Bs',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Estado actual
                        if (estado == 'aceptado')
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.store, color: Colors.orange[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ACEPTADO - Ve al restaurante',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (estado == 'recibido')
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.delivery_dining, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'EN RUTA - Ve al cliente',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 12),
                        
                        // Productos
                        const Text(
                          'Productos:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(pedido['productos'] as List).map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: accentYellow.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${p['cantidad']}x',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p['nombre'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  
                  // Botones de acción
                  if (estado == 'buscando' || estado == 'pendiente' || estado == 'disponible')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _procesarAccionPedido(pedido['id'], 'aceptado'),
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text('ACEPTAR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _procesarAccionPedido(pedido['id'], 'rechazado'),
                              icon: const Icon(Icons.cancel, size: 20),
                              label: const Text('RECHAZAR'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryRed,
                                side: BorderSide(color: primaryRed, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (esMio)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToDetail(pedido),
                          icon: const Icon(Icons.visibility),
                          label: const Text('VER DETALLES Y GESTIONAR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}