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
  BitmapDescriptor _driverIcon = BitmapDescriptor.defaultMarker;

  GoogleMapController? _mapController;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(-17.783306, -63.182139), // Santa Cruz, Bolivia
    zoom: 15,
  );

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // 1. Inicializa el estado con los marcadores que conoces de inmediato.
    _markers.add(Marker(
      markerId: const MarkerId('restaurante'),
      position: const LatLng(-17.783306, -63.182139),
      infoWindow: const InfoWindow(title: 'Restaurante'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ));
    // 2. Carga los assets asíncronos.
    _loadDriverIcon();
    // 3. Inicia la carga de datos de la red.
    _startFetchingDriverLocations();
  }

  Future<void> _loadDriverIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/motorcycle_icon.png', // Asegúrate de tener este asset
    );
    if (mounted) {
      setState(() {
        _driverIcon = icon;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelamos el timer para evitar fugas de memoria
    super.dispose();
  }


  void _startFetchingDriverLocations() {
    // Ejecutamos la primera vez inmediatamente
    _updateDriverMarkers();
    
    // Y luego configuramos el timer para que se repita cada 10 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateDriverMarkers();
    });
  }

  Future<void> _updateDriverMarkers() async {
    try {
      final List<dynamic> conductores = await _apiService.getConductoresActivos();
      print("[map-screen] Conductores recibidos: $conductores"); // DEBUG: Imprimir datos recibidos

      final Set<Marker> newMarkers = {};

      // 1. Añadir el marcador del restaurante
      newMarkers.add(Marker(
        markerId: const MarkerId('restaurante'),
        position: const LatLng(-17.783306, -63.182139),
        infoWindow: const InfoWindow(title: 'Restaurante'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));

      // 2. Añadir los marcadores de los conductores
      for (var conductor in conductores) {
        final ubicacion = conductor['ubicacion'];
        if (ubicacion != null && ubicacion['coordenadas'] != null) {
          try {
            final parts = ubicacion['coordenadas'].split(',');
            if (parts.length == 2) {
              final lat = double.tryParse(parts[0].trim());
              final lng = double.tryParse(parts[1].trim());
              if (lat != null && lng != null) {
                newMarkers.add(
                  Marker(
                    markerId: MarkerId('conductor_${conductor['id']}'),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(title: conductor['nombre']),
                    icon: _driverIcon,
                  ),
                );
              }
            }
          } catch (e) {
            print("[map-screen] Error al parsear coordenadas para ${conductor['nombre']}: ${ubicacion['coordenadas']}");
          }
        }
      }

      // 3. Actualizar el estado con el nuevo conjunto de marcadores
      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(newMarkers);
        });
        print("[map-screen] Marcadores actualizados: ${_markers.length}"); // DEBUG: Contar marcadores
      }

    } catch (e) {
      print("[map-screen]Error al obtener la ubicación de los conductores: $e");
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
