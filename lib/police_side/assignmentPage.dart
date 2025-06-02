import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mainapp/token_helper.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'scan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({Key? key}) : super(key: key);

  @override
  _AssignmentPageState createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  List<dynamic> Assignments = [];
  bool AssignmentLoaded = false;

  late GoogleMapController mapController;

  final LatLng _center = const LatLng(-33.86, 151.20);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  bool _isNearCheckpoint(LatLng userLocation, List<dynamic> checkpoints) {
    const double maxDistanceMeters = 100; // 100 meters radius

    for (var checkpoint in checkpoints) {
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        checkpoint[0],
        checkpoint[1],
      );

      if (distance <= maxDistanceMeters) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    fetchAssignments(context);
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: SingleChildScrollView(
        child: !AssignmentLoaded
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        "Loading assignments...",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: Assignments.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "No Assignments Allocated",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      ]
                    : Assignments.map<Widget>((element) {
                        final startDate = DateTime.tryParse(
                            element['startsAt']?.toString() ?? '');
                        final endDate = DateTime.tryParse(
                            element['endsAt']?.toString() ?? '');

                        return _modifiedCard(
                            title: 'Assignment',
                            areas: element['checkpoints'] ?? '',
                            startDate: startDate,
                            endDate: endDate,
                            isActive:
                                !isPastEndTime(element['endsAt'].toString()),
                            assignmentId: element['_id']);
                      }).toList(),
              ),
      ),
    );
  }

  Widget showMap(List<dynamic> checkpoints) {
    // print(checkpoints);
    LatLng initialPosition = checkpoints.isNotEmpty
        ? LatLng(checkpoints[0][0], checkpoints[0][1])
        : _center;

    Set<Marker> markers = checkpoints.asMap().entries.map((entry) {
      // print(entry.value);
      int index = entry.key;
      LatLng position = LatLng(entry.value[0], entry.value[1]);

      return Marker(
        markerId: MarkerId('checkpoint_$index'), // Unique ID for each marker
        position: position, // The LatLng position
        infoWindow: InfoWindow(
            title: 'Checkpoint ${index + 1}'), // Optional: Add a label
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkpoints'),
        backgroundColor: const Color.fromARGB(255, 18, 112, 188),
      ),
      body: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _onMapCreated(controller); // Your existing callback
            if (checkpoints.isNotEmpty) {
              // Calculate bounds that include all markers
              final bounds = boundsFromLatLngList(
                checkpoints.map((point) => LatLng(point[0], point[1])).toList(),
              );
              controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 50)); // 50 = padding
            }
          },
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 11.0,
          ),
          // markers: {
          //   const Marker(
          //     markerId: const MarkerId("Checkpoint"),
          //     position: LatLng(-33.86, 151.20),
          //   ), // Marker
          // },
          markers: markers // markers
          ), // GoogleMap
    );
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
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
        northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  Widget _modifiedCard({
    required String title,
    required List<dynamic> areas,
    required DateTime? startDate,
    required DateTime? endDate,
    required String assignmentId,
    bool isActive = false,
  }) {
    bool isAtLocation = false;

    return FutureBuilder<Position>(
        future: Geolocator.getCurrentPosition(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userLocation = LatLng(
              snapshot.data!.latitude,
              snapshot.data!.longitude,
            );
            isAtLocation = _isNearCheckpoint(userLocation, areas);
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isActive
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Location section with multiple areas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Checkpoint(s):',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                            const Spacer(),
                            // View Checkpoints Button
                            InkWell(
                              onTap: () {
                                // Navigate to checkpoints widget
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => showMap(areas),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.list,
                                        size: 16, color: Colors.blue[800]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'View',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.blue[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Scan Checkpoint Button
                            InkWell(
                              onTap: isAtLocation && isActive
                                  ? () {
                                      _startCheckpointScan(assignmentId);
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAtLocation && isActive
                                      ? Colors.green[50]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isAtLocation && isActive
                                        ? Colors.green
                                        : Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.qr_code_scanner,
                                        size: 16,
                                        color: isAtLocation && isActive
                                            ? Colors.green[800]
                                            : Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Scan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: isAtLocation && isActive
                                                ? Colors.green[800]
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (areas.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 28.0),
                            child: Text(
                              'No areas assigned',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 28.0),
                            child: Text(areas.length > 1
                                ? "${areas.length} checkpoints"
                                : "${areas.length} checkpoint"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date and Time Badge
                    if (startDate != null && endDate != null)
                      _buildDateTimeBadge(startDate, endDate),
                  ],
                ),
              ),
            ),
          );
        });
  }

// Placeholder function for scanning
  void _startCheckpointScan(String assignmentId) async {
  final position = await Geolocator.getCurrentPosition();
  final userLocation = LatLng(position.latitude, position.longitude);
  
  // Get the assignment to check checkpoints
  final assignment = Assignments.firstWhere(
    (a) => a['_id'] == assignmentId,
    orElse: () => null,
  );
  
  if (assignment == null || !_isNearCheckpoint(userLocation, assignment['checkpoints'])) {
    Fluttertoast.showToast(
      msg: "You must be at a checkpoint location to scan",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return;
  }
  
  final success = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (context) => ScanCheckpointPage(assignmentId: assignmentId)),
  );

  if (success == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checkpoint Scanned Successfully')),
    );
  }
}

  Widget _buildDateTimeBadge(DateTime startsAt, DateTime endsAt) {
    final isSameDay = startsAt.toLocal().year == endsAt.toLocal().year &&
        startsAt.toLocal().month == endsAt.toLocal().month &&
        startsAt.toLocal().day == endsAt.toLocal().day;

    final dateText = isSameDay
        ? DateFormat('MMM d, yyyy').format(startsAt.toLocal())
        : '${DateFormat('MMM d').format(startsAt.toLocal())} - ${DateFormat('MMM d, yyyy').format(endsAt.toLocal())}';

    final startTime = DateFormat('h:mm a').format(startsAt.toLocal());
    final endTime = DateFormat('h:mm a').format(endsAt.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100] ?? Colors.blue, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 16, color: Colors.blue[800]),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$dateText • $startTime - $endTime',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  bool isPastEndTime(String endsAtString) {
    try {
      // Parse the ISO 8601 string into a DateTime object
      final endsAtDateTime = DateTime.parse(endsAtString);

      // Compare with the current time
      return endsAtDateTime.isBefore(DateTime.now());
    } catch (e) {
      // If parsing fails, assume the time is not in the past
      return false;
    }
  }

  Future<void> fetchAssignments(BuildContext context) async {
    String? token = await TokenHelper.getToken();
    try {
      final response = await http.get(
        Uri.parse(
            'https://patrollingappbackend.onrender.com/api/v1/assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          Assignments = responseData['data'] ?? [];
          AssignmentLoaded = true;
        });
        // print(responseData);
      }
    } catch (e) {
      // Handle any errors that occur during the request
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }
}
