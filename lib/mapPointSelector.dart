import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_maps_webservices/places.dart' as gmaps;
import 'package:geolocator/geolocator.dart';

class MapPointSelector extends StatefulWidget {
  @override
  _MapPointSelectorState createState() => _MapPointSelectorState();
}

class _MapPointSelectorState extends State<MapPointSelector> {
  GoogleMapController? mapController;
  LatLng? selectedPoint;
  Marker? selectedMarker;
  final TextEditingController searchController = TextEditingController();
  final places = gmaps.GoogleMapsPlaces(apiKey: dotenv.env["MAPS_API_KEY"] ?? "");
  

  Set<Marker> markers = {};
  List<LatLng> selectedPoints = [];
  int markerCounter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Point on Map'),
        actions:[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              if (selectedPoints.isNotEmpty) {
                Navigator.pop(context, selectedPoints);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_out_map),
            onPressed: _zoomToFit,
          ),
        ],
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search location...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed:_searchLocation,
                ),
              ),
              onSubmitted: (_) => _searchLocation(),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(25.1338702361743278, 82.56418537348509),
                zoom: 14,
              ),
              onMapCreated: (controller) {
                setState(() {
                  mapController = controller;
                });
              },
              onTap: (LatLng position) {
                _addMarker(position);
              },
              markers: markers,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'btn1',
            mini: true,
            child: Icon(Icons.delete),
            onPressed: _clearMarkers,
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'btn2',
            child: Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
          ),
        ],
      ),
    );
  }

  Future<void> _searchLocation() async {
  try {
    if (searchController.text.isEmpty) {
      print('Search text is empty');
      return;
    }
    
    print('Searching for: ${searchController.text}');
    
    final response = await places.searchByText(searchController.text);
    
    if (response.results.isEmpty) {
      print('No results found');
      return;
    }
    
    final firstResult = response.results.first;
    if (firstResult.geometry?.location == null) {
      print('First result has no geometry');
      return;
    }
    
    final location = firstResult.geometry!.location;
    final latLng = LatLng(location.lat, location.lng);
    
    print('Found location: $latLng');
    
    setState(() {
      selectedPoint = latLng;
      selectedMarker = Marker(
        markerId: const MarkerId('selected_point'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    });
    
    if (mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 14),
      );
    } else {
      print('Map controller is null');
    }
  } catch (e) {
    print('Error in _searchLocation: $e');
  }
}

  void _addMarker(LatLng position) {
    final String markerIdVal = 'marker_$markerCounter';
    markerCounter++;
    
    final Marker marker = Marker(
      markerId: MarkerId(markerIdVal),
      position: position,
      draggable: true,
      infoWindow: InfoWindow(
        title: 'Point ${markers.length + 1}',
        snippet: '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
      ),
      onDragEnd: (LatLng newPosition) {
        _updateMarkerPosition(markerIdVal, newPosition);
      },
    );

    setState(() {
      markers.add(marker);
      selectedPoints.add(position);
    });
  }

  void _updateMarkerPosition(String markerId, LatLng newPosition) {
    final int index = selectedPoints.indexWhere(
      (point) => point == markers.firstWhere((m) => m.markerId.value == markerId).position
    );
    
    if (index != -1) {
      setState(() {
        selectedPoints[index] = newPosition;
      });
    }
  }

  void _clearMarkers() {
    setState(() {
      markers.clear();
      selectedPoints.clear();
      markerCounter = 0;
    });
  }
  void _zoomToFit() {
    if (selectedPoints.isEmpty) return;
    
    LatLngBounds bounds = _createBounds(selectedPoints);
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _createBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    
    for (var point in points) {
      minLat = minLat == null ? point.latitude : (point.latitude < minLat ? point.latitude : minLat);
      maxLat = maxLat == null ? point.latitude : (point.latitude > maxLat ? point.latitude : maxLat);
      minLng = minLng == null ? point.longitude : (point.longitude < minLng ? point.longitude : minLng);
      maxLng = maxLng == null ? point.longitude : (point.longitude > maxLng ? point.longitude : maxLng);
    }
    
    return LatLngBounds(
      northeast: LatLng(maxLat!, maxLng!),
      southwest: LatLng(minLat!, minLng!),
    );
  }
  Future<void> _goToCurrentLocation() async {
  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show dialog to enable them
      bool shouldOpenSettings = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await Geolocator.openLocationSettings();
      }
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permissions are permanently denied, we cannot request permissions.'),
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: () async {
              await Geolocator.openAppSettings();
            },
          ),
        ),
      );
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    // Move camera to current location
    LatLng currentLocation = LatLng(position.latitude, position.longitude);
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation, 16),
    );

    // Optionally add a marker at current location
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Current Location'),
        ),
      );
    });

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error getting location: ${e.toString()}')),
    );
  }
}
}