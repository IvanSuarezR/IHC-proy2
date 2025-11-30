import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or your local machine's IP for physical device
  // Update this with the correct IP of your backend machine if running on a physical device.
  // Example: "http://192.168.1.5:8000/delivery" (check with 'ipconfig' or 'ifconfig')
  // Note: The previous path was /api, but the new backend configuration routes through /delivery
  // final String baseUrl = "http://192.168.100.132:8000/delivery";
  final String baseUrl = "https://conductor-backend-608918105626.us-central1.run.app/delivery";

  Future<List<dynamic>> getConductores() async {
    final response = await http.get(Uri.parse('$baseUrl/conductores/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load conductores');
    }
  }

  Future<List<dynamic>> getConductoresActivos() async {
    final response = await http.get(Uri.parse('$baseUrl/conductores/activos/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load active conductores');
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

  Future<void> activarConductor(int id, {String? fcmToken}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conductores/$id/activar/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String?>{
        'fcm_token': fcmToken,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to activate conductor');
    }
  }

  Future<void> desactivarConductor(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conductores/$id/desactivar/'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to deactivate conductor');
    }
  }

  Future<void> actualizarUbicacion(int conductorId, String coordenadas) async {
    // The ubicaciones endpoint might not be set up for POST to create/update
    // A common pattern is POST to /ubicaciones/ or PATCH to /ubicaciones/{conductor_id}/
    // Assuming a POST to the collection, creating a new location record or updating if one exists.
    final response = await http.post(
      Uri.parse('$baseUrl/ubicaciones/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'conductor': conductorId,
        'coordenadas': coordenadas,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update ubicacion: ${response.statusCode} ${response.body}');
    }
  }
}
