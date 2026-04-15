
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mapa")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(-12.2664, -38.9663),
          zoom: 14,
        ),
      ),
    );
  }
}
