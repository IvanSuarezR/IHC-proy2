import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(-17.783306, -63.182139), // Santa Cruz, Bolivia
    zoom: 15,
  );

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('restaurante'),
      position: LatLng(-17.783306, -63.182139),
      infoWindow: InfoWindow(title: 'Restaurante'),
    )
  };

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
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMapOnUserLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _centerMapOnUserLocation() async {
    final position = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }
}
