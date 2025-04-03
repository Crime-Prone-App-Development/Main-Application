import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? description;

  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  late LatLng incidentLocation;

  @override
  void initState() {
    super.initState();
    incidentLocation = LatLng(widget.latitude, widget.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.description ?? 'Incident Location'),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        initialCameraPosition: CameraPosition(
          target: incidentLocation,
          zoom: 15.0,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('incident_location'),
            position: incidentLocation,
            infoWindow: InfoWindow(
              title: 'Incident Location',
              snippet: widget.description,
            ),
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openInMapsApp,
        child: const Icon(Icons.navigation),
      ),
    );
  }

  Future<void> _openInMapsApp() async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch maps')),
      );
    }
  }
}