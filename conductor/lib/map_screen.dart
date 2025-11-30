import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:conductor/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;

  GoogleMapController? _mapController;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(-17.783306, -63.182139), // Santa Cruz, Bolivia
    zoom: 15,
  );

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _startFetchingDriverLocations();
    // Añadimos el marcador del restaurante desde el inicio.
    _addRestaurantMarker();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelamos el timer para evitar fugas de memoria
    super.dispose();
  }

  void _addRestaurantMarker() {
     _markers.add(
      Marker(
        markerId: MarkerId('restaurante'),
        position: LatLng(-17.783306, -63.182139), // Coordenadas fijas del restaurante
        infoWindow: InfoWindow(title: 'Restaurante'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  void _startFetchingDriverLocations() {
    // Ejecutamos la primera vez inmediatamente
    _updateDriverMarkers();
    
    // Y luego configuramos el timer para que se repita cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateDriverMarkers();
    });
  }

  Future<void> _updateDriverMarkers() async {
    try {
      final List<dynamic> conductores = await _apiService.getConductoresActivos();
      final Set<Marker> updatedMarkers = {};

      // Siempre mantenemos el marcador del restaurante
      final restaurantMarker = _markers.firstWhere((m) => m.markerId.value == 'restaurante', orElse: () => _createRestaurantMarker());
      updatedMarkers.add(restaurantMarker);

      for (var conductor in conductores) {
        final ubicacion = conductor['ubicacion'];
        if (ubicacion != null && ubicacion['coordenadas'] != null) {
          try {
            final parts = ubicacion['coordenadas'].split(',');
            if (parts.length == 2) {
              final lat = double.parse(parts[0]);
              final lng = double.parse(parts[1]);
              updatedMarkers.add(
                Marker(
                  markerId: MarkerId('conductor_${conductor['id']}'),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(title: conductor['nombre']),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
              );
            }
          } catch (e) {
            print("Error al parsear coordenadas para ${conductor['nombre']}: ${ubicacion['coordenadas']}");
          }
        }
      }

      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(updatedMarkers);
        });
      }

    } catch (e) {
      print("Error al obtener la ubicación de los conductores: $e");
    }
  }
   
  Marker _createRestaurantMarker() {
    return Marker(
      markerId: MarkerId('restaurante'),
      position: LatLng(-17.783306, -63.182139),
      infoWindow: InfoWindow(title: 'Restaurante'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación de Repartidores'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
