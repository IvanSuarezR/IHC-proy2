import 'package:conductor/api_service.dart';
import 'package:conductor/map_screen.dart';
import 'package:flutter/material.dart';

class OrderScreen extends StatefulWidget {
  final String conductor;

  const OrderScreen({super.key, required this.conductor});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ApiService apiService = ApiService();
  late Future<List<dynamic>> pedidos;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    pedidos = apiService.getPedidos();
  }

  void _actualizarEstadoPedido(int id, String estado) {
    apiService.actualizarPedido(id, estado).then((_) {
      setState(() {
        pedidos = apiService.getPedidos();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos para ${widget.conductor}'),
        actions: [
          Switch(
            value: _activo,
            onChanged: (value) {
              setState(() {
                _activo = value;
              });
            },
            activeTrackColor: Colors.lightGreenAccent,
            activeColor: Colors.green,
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
      body: FutureBuilder<List<dynamic>>(
        future: pedidos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pedidos disponibles'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final pedido = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Pedido #${pedido['id']}'),
                    subtitle: Text(pedido['descripcion']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _actualizarEstadoPedido(pedido['id'], 'aceptado'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _actualizarEstadoPedido(pedido['id'], 'rechazado'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
