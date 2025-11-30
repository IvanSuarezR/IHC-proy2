import 'package:conductor/api_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pedido;

  const OrderDetailScreen({super.key, required this.pedido});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService apiService = ApiService();
  // Coordenadas fijas del restaurante según especificación
  static const double restauranteLat = -17.783306;
  static const double restauranteLng = -63.182139;

  String _estadoActual = '';

  @override
  void initState() {
    super.initState();
    _estadoActual = widget.pedido['estado'] ?? 'pendiente';
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    try {
      await apiService.actualizarPedido(widget.pedido['id'], nuevoEstado);
      if (mounted) {
        setState(() {
          _estadoActual = nuevoEstado;
        });
        if (nuevoEstado == 'entregado') {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pedido entregado correctamente.')),
            );
            Navigator.pop(context, true); // Vuelve a la lista solo al terminar
        } else if (nuevoEstado == 'cancelado') {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pedido cancelado.')),
            );
            Navigator.pop(context, true); // Vuelve a la lista
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando pedido: $e')),
        );
      }
    }
  }

  Future<void> _confirmarCancelacion() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar cancelación'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Estás seguro de que quieres cancelar este pedido?'),
                Text('Esta acción no se puede deshacer.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No, volver'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sí, cancelar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _actualizarEstado('cancelado');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirMapa(String? coordenadas) async {
    if (coordenadas == null || coordenadas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay coordenadas disponibles para este pedido')),
        );
        return;
    }
    
    // El formato esperado es "lat,lng"
    final coords = coordenadas.replaceAll(' ', '');
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$coords");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el mapa')),
        );
      }
    }
  }

  String _calcularDistancia(String? coordenadasCliente) {
    if (coordenadasCliente == null || coordenadasCliente.isEmpty) return "Desconocida";
    
    try {
      final parts = coordenadasCliente.split(',');
      if (parts.length != 2) return "Formato inválido";

      double clienteLat = double.parse(parts[0].trim());
      double clienteLng = double.parse(parts[1].trim());

      double distanciaEnMetros = Geolocator.distanceBetween(
        restauranteLat,
        restauranteLng,
        clienteLat,
        clienteLng,
      );

      if (distanciaEnMetros < 1000) {
        return "${distanciaEnMetros.toStringAsFixed(0)} m";
      } else {
        return "${(distanciaEnMetros / 1000).toStringAsFixed(2)} km";
      }
    } catch (e) {
      return "Error al calcular";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el estado local actualizado
    final estado = _estadoActual;
    final coordenadas = widget.pedido['coordenadas'];

    // Usamos PopScope en lugar de WillPopScope (deprecated)
    final bool canPop = !(_estadoActual == 'aceptado' || _estadoActual == 'recibido');

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        // Bloquear back si el pedido está en curso
        if (!canPop) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debes completar el pedido antes de salir.')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detalle Pedido #${widget.pedido['id']}'),
          automaticallyImplyLeading: false,
          leading: (_estadoActual == 'entregado' || _estadoActual == 'cancelado' || _estadoActual == 'rechazado')
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, true))
              : null,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Sección Cliente
            const Text('Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('${widget.pedido['first_name'] ?? 'Sin nombre'}'),
              subtitle: Text('@${widget.pedido['username'] ?? 'sin_usuario'}'),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text('${widget.pedido['phone_number'] ?? 'Sin teléfono'}'),
            ),
            
            const SizedBox(height: 16),
            
            // Sección Dirección y Distancia
            const Text('Ubicación de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
             ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Origen (Restaurante)'),
              subtitle: const Text('Lat: $restauranteLat, Lng: $restauranteLng'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(widget.pedido['direccion']),
              subtitle: Text('Coordenadas: ${coordenadas ?? "No disponibles"}'),
              trailing: IconButton(
                icon: const Icon(Icons.map, color: Colors.blue),
                onPressed: () => _abrirMapa(coordenadas),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Distancia desde Restaurante'),
              subtitle: Text(_calcularDistancia(coordenadas), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),

            const SizedBox(height: 16),

            // Sección Productos
            const Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (widget.pedido['productos'] != null)
              ... (widget.pedido['productos'] as List).map((p) => ListTile(
                leading: CircleAvatar(child: Text('${p['cantidad']}')),
                title: Text(p['nombre']),
                trailing: Text('${p['precio']} Bs'), // Asumiendo moneda
              )),

            const Divider(),
            ListTile(
              title: const Text('Total a Cobrar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              trailing: Text('${widget.pedido['total']} Bs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ),

            const SizedBox(height: 30),

            // Botones de Acción - Usamos _estadoActual directamente
            const SizedBox(height: 30),
            
            if (_estadoActual == 'aceptado') ...[
              const Center(child: Text("Ve al restaurante y recoge el pedido", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _actualizarEstado('recibido'),
                  icon: const Icon(Icons.inventory),
                  label: const Text('YA TENGO EL PEDIDO (MARCAR RECIBIDO)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarCancelacion(),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('CANCELAR PEDIDO', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ] else if (_estadoActual == 'recibido') ...[
              const Center(child: Text("Lleva el pedido al cliente", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _actualizarEstado('entregado'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('ENTREGAR PEDIDO'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarCancelacion(),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('CANCELAR PEDIDO', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ] else if (_estadoActual == 'entregado') ...[
               const Center(
                 child: Text('¡Pedido completado!', style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
               ),
               const SizedBox(height: 20),
                SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('VOLVER A LA LISTA'),
                ),
              ),
            ],
            const SizedBox(height: 50), // Espacio extra al final para asegurar scroll
          ],
        ),
      ),
    ));
  }
}