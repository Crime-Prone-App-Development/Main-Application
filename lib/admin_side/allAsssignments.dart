import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mainapp/admin_side/home.dart';
import 'package:mainapp/admin_side/route_map_page.dart';
import '../token_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'map_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({Key? key}) : super(key: key);

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  List<dynamic> pendingAssignments = [];
  List<dynamic> reviewedAssignments = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> filteredPendingAssignments = [];
  List<dynamic> filteredReviewedAssignments = [];
  String _currentSearchQuery = '';

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
    _searchController.addListener(_filterAssignments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAssignments() {
    _searchDebounce?.cancel();
  
  // Start new debounce
  _searchDebounce = Timer(const Duration(milliseconds: 300), () {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _currentSearchQuery = query;

      if (query.isEmpty) {
        // If search is empty, show all assignments
        filteredPendingAssignments = List.from(pendingAssignments);
        filteredReviewedAssignments = List.from(reviewedAssignments);
      } else {
        // Filter pending assignments
        filteredPendingAssignments = pendingAssignments.where((assignment) {
          return _assignmentMatchesQuery(assignment, query);
        }).toList();

        // Filter reviewed assignments
        filteredReviewedAssignments = reviewedAssignments.where((assignment) {
          return _assignmentMatchesQuery(assignment, query);
        }).toList();
      }
    });
  }); 
  }

  bool _assignmentMatchesQuery(dynamic assignment, String query) {
    // Search in assignment ID
    if (assignment['_id']?.toString().toLowerCase().contains(query) ?? false) {
      return true;
    }

    // Search in officer names
    if (assignment['officer'] is List) {
      for (var officer in assignment['officer']) {
        if (officer['name']?.toString().toLowerCase().contains(query) ??
            false) {
          return true;
        }
      }
    } else if (assignment['officer'] is Map) {
      if (assignment['officer']['name']
              ?.toString()
              .toLowerCase()
              .contains(query) ??
          false) {
        return true;
      }
    }

    // Search in location
    if (assignment['location']?.toString().toLowerCase().contains(query) ??
        false) {
      return true;
    }

    // Search in status
    if (assignment['status']?.toString().toLowerCase().contains(query) ??
        false) {
      return true;
    }

    return false;
  }


  Future<void> _loadAssignments() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? token = await TokenHelper.getToken();
      final response = await http.get(
        Uri.parse(
            '${dotenv.env["BACKEND_URI"]}/assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> allAssignments = responseData['data'] ?? [];

        setState(() {
          pendingAssignments = allAssignments.where((assignment) {
            // If no image data, consider it pending
            if (assignment['imageData'] == null ||
                assignment['imageData'].isEmpty ||
                assignment['imageData'] is! List) {
              return true;
            }

            // Check if any image isn't verified or if status isn't 'reviewed'
            return assignment['imageData']
                .any((image) => image['verified'] != true);
          }).toList();

          reviewedAssignments = allAssignments.where((assignment) {
            // Must have image data and all verified or status is 'reviewed'
            if (assignment['imageData'] == null ||
                assignment['imageData'].isEmpty ||
                assignment['imageData'] is! List) {
              return false;
            }

            return (assignment['imageData']
                .every((image) => image['verified'] == true));
          }).toList();

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load assignments');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  void _navigateToAssignmentDetails(dynamic assignment) {
    // Make a deep copy of the assignment to prevent unintended modifications
    final assignmentCopy = json.decode(json.encode(assignment));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentDetailsPage(
          assignment: assignmentCopy,
          onReview: (reviewedAssignment) {
            // This callback will be called when an assignment is fully reviewed
            setState(() {
              // 1. Remove from pending assignments if it exists there
              pendingAssignments
                  .removeWhere((a) => a['_id'] == reviewedAssignment['_id']);

              // 2. Check if the assignment needs to be added to reviewed
              final isAlreadyReviewed = reviewedAssignments
                  .any((a) => a['_id'] == reviewedAssignment['_id']);

              if (!isAlreadyReviewed) {
                // Add to the beginning of the list (newest first)
                reviewedAssignments.insert(0, reviewedAssignment);
              } else {
                // Update existing reviewed assignment if needed
                final index = reviewedAssignments
                    .indexWhere((a) => a['_id'] == reviewedAssignment['_id']);
                if (index != -1) {
                  reviewedAssignments[index] = reviewedAssignment;
                }
              }
            });
          },
        ),
      ),
    ).then((value) {
      _loadAssignments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assignments',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 67, 156, 234),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                icon: Icon(Icons.pending_actions, color: Colors.white),
                text: 'Pending',
              ),
              Tab(
                icon: Icon(Icons.verified_outlined, color: Colors.white),
                text: 'Reviewed',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search assignments...',
                  prefixIcon: Icon(Icons.search, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Pending Tab - use filtered list
                  _buildAssignmentsList(
                      _currentSearchQuery.isEmpty
                          ? pendingAssignments
                          : filteredPendingAssignments,
                      isLoading),
                  // Reviewed Tab - use filtered list
                  _buildAssignmentsList(
                      _currentSearchQuery.isEmpty
                          ? reviewedAssignments
                          : filteredReviewedAssignments,
                      isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsList(List<dynamic> assignments, bool isLoading) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No assignments found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToAssignmentDetails(assignment),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignment ID: ${assignment['_id'] ?? 'N/A'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (assignment["officer"] is List)
                    ...assignment["officer"]
                        .map<Widget>((officer) => Text(
                              officer["name"]?.toString() ?? 'Unnamed Officer',
                              style: TextStyle(color: Colors.grey.shade600),
                            ))
                        .toList(),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _viewOnMap(context, assignment['checkpoints']);
                      print("location reached");
                    },
                    child: Text("View Location"),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void _viewOnMap(BuildContext context, List<dynamic> checkpoints) {
  if (checkpoints.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No checkpoints available')),
    );
    return;
  }

  // Extract the first checkpoint's coordinates as default
  final firstCheckpoint = checkpoints.first;
  final defaultLat = firstCheckpoint[0]?.toString();
  final defaultLng = firstCheckpoint[0]?.toString();
  final defaultDescription = 'Checkpoint';

  try {
    if (defaultLat == null || defaultLng == null) {
      throw Exception('Invalid coordinates');
    }

    final lat = double.parse(defaultLat);
    final lng = double.parse(defaultLng);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentMapScreen(
          latitude: lat,
          longitude: lng,
          description: defaultDescription,
          checkpoints: checkpoints, // Pass all checkpoints to the map screen
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid location coordinates')),
    );
  }
}

class AssignmentMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String description;
  final List<dynamic> checkpoints;

  const AssignmentMapScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.checkpoints,
  }) : super(key: key);

  @override
  State<AssignmentMapScreen> createState() => _AssignmentMapScreenState();
}

class _AssignmentMapScreenState extends State<AssignmentMapScreen> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignment Locations'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 14,
        ),
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        markers: _createMarkers(),
      ),
    );
  }

  Set<Marker> _createMarkers() {
    return widget.checkpoints.map<Marker>((checkpoint) {
      final lat = double.parse(checkpoint[0]?.toString() ?? '0');
      final lng = double.parse(checkpoint[0]?.toString() ?? '0');
      final description = 'Checkpoint';

      return Marker(
        markerId: MarkerId(widget.checkpoints.indexOf(checkpoint).toString()),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: description,
        ),
      );
    }).toSet();
  }
}

class AssignmentDetailsPage extends StatefulWidget {
  final dynamic assignment;
  final Function(dynamic) onReview;

  const AssignmentDetailsPage({
    Key? key,
    required this.assignment,
    required this.onReview,
  }) : super(key: key);

  @override
  State<AssignmentDetailsPage> createState() => _AssignmentDetailsPageState();
}

class _AssignmentDetailsPageState extends State<AssignmentDetailsPage> {
  bool isReviewed = false;
  bool isReviewing = false;

  @override
  void initState() {
    super.initState();
    // isReviewed = widget.assignment['status'] == 'reviewed';
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assignment Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Assignment Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Assignment ID', widget.assignment['_id']),
                    _buildDetailRow('Assignee',
                        widget.assignment['officer'].map((_) => _["name"])),
                    _buildDetailRow('Start',
                        _formatDateTime(widget.assignment['startsAt'])),
                    _buildDetailRow(
                        'End', _formatDateTime(widget.assignment['endsAt'])),
                    _buildDetailRow(
                        'Status',
                        widget.assignment['imageData']
                                .every((image) => image['verified'] == true || image != null)
                            ? "Verified"
                            : "Not Verified"),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Description Section

            // Assigned Users Images Section
            // if (widget.assignment['officer'] != null &&
            //     widget.assignment['officer'].isNotEmpty)
            //   _buildUserImagesSection(),

            SizedBox(height: 20),

            // Images Verification Section
            widget.assignment['imageData'] != null &&
                    widget.assignment['imageData'].isNotEmpty &&
                    widget.assignment['imageData'].any((image) => image != null)
                ? _buildImageVerificationSection()
                : _buildNoImagesUploadedSection(),

            SizedBox(height: 20),

            // Route Maps Section
            _buildRouteMapsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImagesUploadedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Image Verification'),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.photo_library, size: 48, color: Colors.grey[400]),
                SizedBox(height: 8),
                Text(
                  'No images uploaded',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This assignment has no verification images',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

// New Image Verification Section
  Widget _buildImageVerificationSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('Image Verification'),
      SizedBox(height: 12),
      ...widget.assignment['imageData'].map<Widget>((image) {
        print(image);
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                // Make image clickable
                GestureDetector(
                  onTap: () {
                    _showFullScreenImage(image['imageUrl']);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      image['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.broken_image, size: 50),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Image details section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Uploaded by and verification status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Uploaded by: ${image['officer']?['name'] ?? 'Unknown'}',
                          style: TextStyle(fontSize: 14),
                        ),
                        image['verified'] == true
                            ? Chip(
                                label: Text('Verified'),
                                backgroundColor: Colors.green[50],
                                labelStyle: TextStyle(color: Colors.green),
                                avatar: Icon(Icons.check_circle,
                                    color: Colors.green, size: 18),
                              )
                            : ElevatedButton.icon(
                                onPressed: () => _verifyImage(image['_id']),
                                icon: Icon(Icons.verified, size: 18),
                                label: Text('Verify'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              )
                      ],
                    ),
                    SizedBox(height: 8),
                    // Timestamp
                    if (image['createdAt'] != null)
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            _formatDateTime(image['createdAt']),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 8),
                    // Location coordinates
                    if (image['imgLat'] != null && image['imgLon'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                'Location:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              SizedBox(width: 20), // Indent
                              Text(
                                'Lat: ${image['imgLat']}, Lon: ${image['imgLon']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 8),
                              // Add button to view location on map
                              InkWell(
                                onTap: () {
                                  _viewImageLocationOnMap(
                                    double.parse(image['imgLat'].toString()),
                                    double.parse(image['imgLon'].toString()),
                                    image['officer']?['name'] ?? 'Image Location',
                                  );
                                },
                                child: Text(
                                  'View on map',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ],
  );
}

// Helper function to view image location on map
void _viewImageLocationOnMap(double lat, double lng, String title) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Image Location')),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(lat, lng),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId('image_location'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: title),
            ),
          },
        ),
      ),
    ),
  );
}

// Add this new method to show full screen image
  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Full Size Image'),
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child:
                        Icon(Icons.broken_image, size: 50, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

// Image Verification Function
  Future<void> _verifyImage(String imageId) async {
    try {
      String? token = await TokenHelper.getToken();
      final response = await http.patch(
        Uri.parse(
            '${dotenv.env["BACKEND_URI"]}/selfies/$imageId/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 201) {
        // Update the local state
        setState(() {
          final imageIndex = widget.assignment['imageData']
              .indexWhere((img) => img['_id'] == imageId);
          if (imageIndex != -1) {
            widget.assignment['imageData'][imageIndex]['verified'] = true;
          }
        });

        // Check if all images are now verified
        final allVerified = widget.assignment['imageData']
            .every((image) => image['verified'] == true);

        if (allVerified) {
          // Update the assignment status to 'reviewed'
          widget.assignment['verified'] = true;

          // Notify the parent page about the reviewed assignment
          widget.onReview(widget.assignment);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to verify image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Helper Widgets
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, {bool isStatus = false}) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontSize: 15,
                color: isStatus
                    ? _getStatusColor(value, theme)
                    : theme.textTheme.bodyLarge?.color,
                fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status, ThemeData theme) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      default:
        return theme.textTheme.bodyLarge?.color ?? Colors.black;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      print(dateTime);
      print(DateTime.parse(dateTime));
      print(DateTime.parse(dateTime).toLocal());


      final dt = DateTime.parse(dateTime).toLocal();
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  Widget _buildRouteMapsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Route Maps'),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.assignment['officer'].map<Widget>((user) {
            return ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteMapPage(
                      userId: user['_id'],
                      userName: user['name'],
                      assignmentId: widget.assignment['_id'],
                      assignmentStartTime: widget.assignment['startsAt'],
                      assignmentEndTime: widget.assignment['endsAt'],
                    ),
                  ),
                );
                print("route map");
              },
              icon: Icon(Icons.map, size: 18),
              label: Text('${user['name']}\'s Route'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewButtonSection() {
    return Center(
      child: Column(
        children: [
          if (!isReviewed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // onPressed: isReviewing ? null : () {_verifyImage(selfieId)},
                onPressed: () => print("reviewed"),
                icon: Icon(Icons.verified),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    isReviewing ? 'Processing Review...' : 'Mark as Reviewed',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (isReviewed)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: Icon(Icons.check_circle, color: Colors.green),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Reviewed',
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.green),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
