import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mainapp/police_side/appbar.dart';

class CheckpointsPage extends StatefulWidget {
  @override
  State<CheckpointsPage> createState() => _CheckpointsPageState();
}

class _CheckpointsPageState extends State<CheckpointsPage> {
  Completer<GoogleMapController> _controller = Completer();

  static CameraPosition loc =
      const CameraPosition(target: LatLng(26.511639, 80.230954), zoom: 14);

  List<Marker> _marker = [];
  final List<Marker> _list = [
    const Marker(
        markerId: MarkerId("1"),
        position: LatLng(26.514323, 80.231223),
        infoWindow: InfoWindow(title: "Current position"))
  ];

  @override
  void initState() {
    //TODO: implement initState
    super.initState();
    loadData();
  }

  Future<Position> getUserCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  loadData() {
    getUserCurrentLocation().then((value) async {
      print("My Current Location");
      print("${value.latitude} ${value.longitude}");
      _marker.add(
        Marker(
            markerId: MarkerId("2"),
            position: LatLng(value.latitude, value.longitude),
            infoWindow: InfoWindow(title: "My Current location")),
      );
      CameraPosition cameraPosition = CameraPosition(
          zoom: 14, target: LatLng(value.latitude, value.longitude));

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Appbar0(),
          Expanded(
            child: Stack(
              children: [
                // Map Section (Fixed Height)
                FutureBuilder<Position>(
                  future: getUserCurrentLocation(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Container(
                        height: 500, // Fixed height for map
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              snapshot.data!.latitude,
                              snapshot.data!.longitude,
                            ),
                            zoom: 14,
                          ),
                          markers: Set<Marker>.of(_marker),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          onMapCreated: (controller) {
                            _controller.complete(controller);
                          },
                        ),
                      );
                    }
                    return Center(child: CircularProgressIndicator());
                  },
                ),

                // Scrollable Content Overlay
                Positioned.fill(
                  top: 500, // Match map height
                  child: SingleChildScrollView(
                    // physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 24),
                              SizedBox(width: 8),
                              Text(
                                "Total Checkpoints (2)",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Checkpoints List
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCheckpointItem(1, "Checkpoint 1 <name>"),
                              SizedBox(height: 8),
                              _buildCheckpointItem(2, "Checkpoint 2 <name>"),
                            ],
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointItem(int number, String name) {
    return Row(
      children: [
        Text("$number. ",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(name, style: TextStyle(fontSize: 16)),
        Icon(Icons.check_circle, color: Colors.green),
      ],
    );
  }
}
