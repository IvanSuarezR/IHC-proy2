import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://192.168.100.132:8000/api";

  Future<List<dynamic>> getConductores() async {
    final response = await http.get(Uri.parse('$baseUrl/conductores/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load conductores');
    }
  }

  Future<List<dynamic>> getPedidos() async {
    final response = await http.get(Uri.parse('$baseUrl/pedidos/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load pedidos');
    }
  }

  Future<void> actualizarPedido(int id, String estado) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/pedidos/$id/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'estado': estado,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update pedido');
    }
  }
}
