import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mainapp/token_helper.dart';
import './home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';




class RouteMapPage extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? assignmentId;
  final String? assignmentStartTime;
  final String? assignmentEndTime;

  const RouteMapPage({Key? key, required this.userId, this.userName, this.assignmentId, this.assignmentStartTime, this.assignmentEndTime})
      : super(key: key);
  
  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  List<LatLng> routeCoordinates = [];
  bool _isLoading = true;
  String? _errorMessage;
  Completer<GoogleMapController> _controller = Completer();

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  Future<void> _zoomToFit() async {
    if (routeCoordinates.isEmpty) return;

    final GoogleMapController controller = await _controller.future;
    final LatLngBounds bounds = _boundsFromLatLngList(routeCoordinates);
    
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
    controller.animateCamera(cameraUpdate);
  }

  Future<List<LatLng>> fetchRoute() async {
    try {
      final userData = await TokenHelper.getUserData();
      final token = userData[0];
      final response = await http.get(
        Uri.parse('${dotenv.env["BACKEND_URI"]}/gps/logs?officerId=${widget.userId}&startTime=${widget.assignmentStartTime}&endTime=${widget.assignmentEndTime}&limit=250'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load route: ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body);
      final coordinates = responseData['data'] as List;

      if (coordinates.isEmpty) {
        throw Exception('No route found');
      }

      return coordinates.map<LatLng>((coord) => 
        LatLng(coord["location"][0], coord["location"][1])
      ).toList();
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCoord();
  }

  Future<void> _loadCoord() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  
  try {
    final coords = await fetchRoute();
    setState(() {
      routeCoordinates = coords;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} Route Path'),
        centerTitle: true,
        actions:[
          IconButton(
            icon: Icon(Icons.zoom_out_map),
            onPressed: _zoomToFit,
          ),
        ],
      ),
      body: _buildMapContent(),
    );
  }


  Widget _buildMapContent() {
  if (_isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading Route Data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  if (_errorMessage != null) {
    return _buildErrorState();
  }

  if (routeCoordinates.isEmpty) {
    return _buildEmptyState();
  }

  return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        _zoomToFit();
      },
      initialCameraPosition: CameraPosition(
        target: routeCoordinates.first,
        zoom: 14,
      ),
      markers: {
        Marker(
          markerId: MarkerId('start'),
          position: routeCoordinates.first,
          infoWindow: InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        Marker(
          markerId: MarkerId('end'),
          position: routeCoordinates.last,
          infoWindow: InfoWindow(title: 'End'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      },
      polylines: {
        Polyline(
          polylineId: PolylineId('route'),
          points: routeCoordinates,
          color: const Color.fromARGB(255, 46, 142, 220),
          width: 8,
        ),
      },
    );
}
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.explore_outlined, size: 64, color: Colors.grey[400]),
        SizedBox(height: 16),
        Text(
          'No Patrol Data Found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            'The officer has no recorded coordinates for the selected time period.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ),
        SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadCoord,
          icon: Icon(Icons.refresh),
          label: Text('Try Again'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
      ],
    ),
  );
}

Widget _buildErrorState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
        SizedBox(height: 16),
        Text(
          'Unable to Load Route',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[600],
          ),
        ),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            _errorMessage ?? 'An unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _loadCoord,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red[400],
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(width: 16),
            TextButton.icon(
              onPressed: () {
                // Add your contact support action here
              },
              icon: Icon(Icons.help_outline),
              label: Text('Help'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}
