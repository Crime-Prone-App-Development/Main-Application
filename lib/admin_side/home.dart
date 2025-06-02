import 'dart:ffi' as ffi;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mainapp/admin_side/alert.dart';
import 'package:mainapp/admin_side/allAsssignments.dart';
import 'package:mainapp/admin_side/checkpoints.dart';
import 'package:mainapp/admin_side/patrolroutes.dart';
import 'package:mainapp/admin_side/reports.dart';
import 'package:mainapp/admin_side/route_map_page.dart';
import 'package:mainapp/police_side/checkpoint.dart';
import 'package:mainapp/police_side/home.dart';
// import 'package:path/path.dart';
import '../token_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import './officersTable.dart';
import 'assign.dart';
import 'package:intl/intl.dart';
import 'map_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:io';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:mainapp/notifications_service.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

import 'package:mainapp/loginpage.dart';

class adminHome extends StatefulWidget {
  @override
  _adminHomeState createState() => _adminHomeState();
}

class _adminHomeState extends State<adminHome> {

  Map<String, dynamic> _connectedUsers = {}; // Track connected users with their data
  Map<String, Marker> _connectedUsersMarkers = {};

  Map<String, Marker> _allUsersMarkers = {}; // Track all users with their IDs
  List<dynamic> _allUsers = []; // Store complete user data
  bool _loadingUsers = false;

  Set<Marker> _userMarkers = {};
  late GoogleMapController _mapController;
  final LatLng _center = const LatLng(26.511639, 80.230954);

  bool _isSidebarOpen = false;
  final double _sidebarWidth = 230.0;
  List<dynamic> allReports = [];
  bool reportsLoaded = false;
  final List<PatrolRoute> _routes = [
    PatrolRoute(
      position: LatLng(26.511639, 80.230954),
      id: 1,
      name: 'Main Entrance',
      guards: ['John Doe', 'Jane Smith'],
      isActive: true,
      lastUpdated: '10/15/23',
    ),
    PatrolRoute(
      position: LatLng(26.511639, 80.230954),
      id: 2,
      name: 'Parking Lot',
      guards: ['Mike Johnson'],
      isActive: true,
      lastUpdated: '10/14/23',
    ),
    PatrolRoute(
      position: LatLng(26.511639, 80.230954),
      id: 3,
      name: 'Warehouse Area',
      guards: ['Sarah Connor'],
      isActive: false,
      lastUpdated: '10/10/23',
    ),
    PatrolRoute(
      position: LatLng(26.511639, 80.230954),
      id: 4,
      name: 'Front Gate',
      guards: ['John Doe'],
      isActive: true,
      lastUpdated: '10/12/23',
    ),
  ];

  Future<void> _connectToSocket() async {
  String? token = await TokenHelper.getToken();
  IO.Socket socket = IO.io(
    'https://patrollingappbackend.onrender.com',
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders({'authorization': "$token"})
        .build(),
  );

  socket.onConnect((_) {
    print('Connected to Socket Server');
    socket.emit('registerAdmin');
    _fetchAllUsers(); // Load all users when connected
  });

  socket.on('userConnected', (userId) {
    if (mounted) {
      setState(() {
        // Find the user in _allUsers and add to connected users
        final user = _allUsers.firstWhere(
          (u) => u['_id'] == userId,
          orElse: () => null,
        );
        if (user != null) {
          _connectedUsers[userId] = user;
          _updateConnectedMarkers();
        }
      });
    }
  });

  socket.on('userLocation', (data) {
    if (mounted) {
      setState(() {
        // Only update if user is connected
        if (_connectedUsers.containsKey(data['userId'])) {
          _connectedUsers[data['userId']] = {
            ..._connectedUsers[data['userId']],
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'lastUpdate': DateTime.now().toIso8601String(),
          };
          _updateConnectedMarkers();
        }
      });
    }
  });



  socket.on('alert', (data) async {
  String alertTitle = data['type'] == 'panic' 
      ? 'PANIC ALERT!' 
      : 'INCIDENT ALERT';
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(alertTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${data['userName']}'),
            SizedBox(height: 8),
            Text('Location: ${data['location']}'),
            SizedBox(height: 8),
            if (data['description'] != null) 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description:'),
                  Text(data['description']),
                ],
              ),
            SizedBox(height: 8),
            Text('Time: ${(data['timestamp'])}'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('ACKNOWLEDGE'),
            onPressed: () {
              socket.emit('acknowledge-alert', {
                'alertId': data['alertId'],
                'adminId': "currentAdminId",
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
  
  // Show notification
  await NotificationService.showNotification(
  id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
  title: alertTitle,
  body: data['type'] == 'panic' 
      ? 'Immediate assistance needed from ${data['userName']}' 
      : 'Incident reported by ${data['userName']}',
  // payload: json.encode(data), // Optional payload
);
});



  // Handle disconnections
  socket.on('userDisconnected', (userId) {
    if (mounted) {
      setState(() {
        _connectedUsers.remove(userId);
        _connectedUsersMarkers.remove(userId);
      });
    }
  });

  socket.onDisconnect((_) => print('Disconnected from server'));
}

void _updateConnectedMarkers() {
  final newMarkers = <String, Marker>{};
  
  for (var user in _connectedUsers.values) {
    if (user['latitude'] != null && user['longitude'] != null) {
      newMarkers[user['_id']] = Marker(
        markerId: MarkerId(user['_id']),
        position: LatLng(user['latitude'], user['longitude']),
        infoWindow: InfoWindow(
          title: user['name'] ?? 'Officer',
          snippet: 'Updated: ${DateTime.parse(user['lastUpdate']) ?? 'Unknown'}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          user['role'] == 'admin' 
            ? BitmapDescriptor.hueRed 
            : BitmapDescriptor.hueBlue,
        ),
      );
    }
  }
  
  setState(() => _connectedUsersMarkers = newMarkers);
}
Future<void> _fetchAllUsers() async {
  setState(() => _loadingUsers = true);
  String? token = await TokenHelper.getToken();
  
  try {
    final response = await http.get(
      Uri.parse('https://patrollingappbackend.onrender.com/api/v1/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _allUsers = data['data'] ?? [];
        // _updateMarkersFromUsers();
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load users: ${e.toString()}')),
    );
  } finally {
    setState(() => _loadingUsers = false);
  }
}

// void _updateMarkersFromUsers() {
//   final newMarkers = <String, Marker>{};
  
//   for (var user in _allUsers) {
//     if (user['latitude'] != null && user['longitude'] != null) {
//       newMarkers[user['_id']] = Marker(
//         markerId: MarkerId(user['_id']),
//         position: LatLng(user['latitude'], user['longitude']),
//         infoWindow: InfoWindow(
//           title: 'Officer',
//           snippet: 'Last update: ${user['lastUpdate'] ?? 'Unknown'}',
//         ),
//         icon: BitmapDescriptor.defaultMarkerWithHue(
//           user['role'] == 'admin' 
//             ? BitmapDescriptor.hueRed 
//             : BitmapDescriptor.hueBlue,
//         ),
//       );
//     }
//   }
  
//   setState(() => _allUsersMarkers = newMarkers);
// }

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    fetchReport(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMainContent(),

          // Sidebar Overlay
          if (_isSidebarOpen)
            GestureDetector(
              onTap: () => setState(() => _isSidebarOpen = false),
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

          // Sidebar
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isSidebarOpen ? 0 : -_sidebarWidth,
            top: 0,
            bottom: 0,
            child: _buildSidebar(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 20),
                _buildStatsGrid(),
                SizedBox(height: 20),
                _buildMainGrid(),
                SizedBox(height: 10),
                _buildRecentItemsGrid(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 60,
      color: Color(0xFF82BAFA),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
              ),
              SizedBox(width: 10),
              CircleAvatar(backgroundImage: AssetImage('assets/profile.png')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: _sidebarWidth,
      color: Color(0xFFECE7E7),
      child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(top: 20, left: 8),
            children: [
              _buildMenuItem('Dashboard', Icons.dashboard, adminHome()),
              _buildMenuItem('Assign Police Officers', Icons.people, AdminApp()),
              _buildMenuItem(
                  'Reports', Icons.assignment, ReportsPage(reports: allReports)),
              _buildMenuItem("Assignments", Icons.assignment_ind_outlined, AssignmentsPage()),
              // _buildMenuItem(
              //     'test', Icons.assignment, RouteMapPage()),
            ],
          ),
        ),
        _buildLogoutButton(), // This will now appear at the bottom
      ],
    ),
    );
  }

  Widget _buildLogoutButton() {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Colors.grey.shade300))),
    child: ListTile(
      leading: Icon(Icons.logout, color: Colors.red),
      title: Text('Logout', style: TextStyle(color: Colors.red)),
      contentPadding: EdgeInsets.zero,
      onTap: _handleLogout,
    ),
  );
}
Future<void> _handleLogout() async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Logout'),
      content: Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: Text('Logout', style: TextStyle(color: Colors.red)),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );

  if (shouldLogout == true) {
    await TokenHelper.clearData();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }
}

  Widget _buildMenuItem(String title, IconData icon, Widget destinationWidget) {
    return ListTile(
      leading: Icon(icon, size: 25),
      title: Text(title, style: TextStyle(fontSize: 16)),
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      dense: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationWidget),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dashboard Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Monitor your Police Officers in real time',
            style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
            'Active Police Officers', _connectedUsers.length.toString() , Icons.people, Colors.blue),
        _buildStatCard('Active Routes', '0', Icons.map, Colors.purple),
        _buildStatCard('Alerts Today', '0', Icons.warning, Colors.red),
        _buildStatCard(
            'Completion Rate', '0%', Icons.check_circle, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color)),
                Row(children: [
                  Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                  Text('10%', style: TextStyle(color: Colors.green)),
                ]),
              ],
            ),
            Spacer(),
            Text(value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildMainGrid() {
    return Column(
      children: [
        // InkWell(
        //   onTap: () {
        //     Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => FullScreenRouteMap(routes: _routes),
        //         ));
        //   },
        //   child: Container(
        //     height: 300,
        //     decoration: BoxDecoration(
        //       color: const Color.fromARGB(255, 174, 235, 230),
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //     child: Center(
        //       child: Text(
        //         "Click to view all patrol routes on map",
        //         style: TextStyle(
        //             fontSize: 20,
        //             fontWeight: FontWeight.bold,
        //             color: Colors.grey[700]),
        //       ),
        //     ),
        //   ),
        // ),
         Container(
        height: 300,
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                // Center on all markers after a small delay
                Future.delayed(Duration(milliseconds: 500), () {
                  _centerMapOnMarkers();
                });
              },
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0,
              ),
              markers: _connectedUsersMarkers.values.toSet(),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            if (_loadingUsers)
              Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      SizedBox(height: 16),
      _buildUsersListCard(),
        SizedBox(width: 16),
      ],
    );
  }

  Map<String, String> formatTimestamp(String timestamp) {
  try {
    // Extract just the date portion (before the first space)
    String datePart = timestamp.split(' ').first;
    
    // Parse to DateTime object
    DateTime dateTime = DateTime.parse(datePart);
    
    // Format the outputs
    return {
      'time': DateFormat('HH:mm').format(dateTime),
      'date': DateFormat('dd/MM/yyyy').format(dateTime),
    };
  } catch (e) {
    // Return default values if parsing fails
    print('Error formatting timestamp: $e');
    return {
      'time': '00:00',
      'date': '01 01 1970',
    };
  }
}

  Widget _buildUsersListCard() {
  return Card(
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Officers (${_connectedUsers.length})',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _fetchAllUsers,
                tooltip: "Refresh",
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 150,
            child: _loadingUsers
                ? Center(child: CircularProgressIndicator())
                : _connectedUsers.isEmpty
                    ? Center(child: Text('No officers currently connected'))
                    : ListView.builder(
                        itemCount: _connectedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _connectedUsers.values.elementAt(index);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Icon(Icons.person, color: Colors.blue),
                            ),
                            title: Text(user['name'] ?? 'Officer'),
                            subtitle: Text("${formatTimestamp(user["lastUpdate"])['time']} ${formatTimestamp(user["lastUpdate"])['date']}"?? 'Officer'),
                            trailing: IconButton(
                              icon: Icon(Icons.location_on),
                              color: Colors.blue,
                              onPressed: () {
                                final marker = _connectedUsersMarkers[user['_id']];
                                if (marker != null) {
                                  _mapController.animateCamera(
                                    CameraUpdate.newLatLngZoom(marker.position, 16),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _centerMapOnMarkers() async {
  if (_allUsersMarkers.isEmpty) return;

  LatLngBounds bounds = _boundsFromMarkers(_allUsersMarkers.values.toSet());
  _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
}

LatLngBounds _boundsFromMarkers(Set<Marker> markers) {
  double? minLat, maxLat, minLng, maxLng;
  
  for (var marker in markers) {
    minLat = minLat == null ? marker.position.latitude : min(minLat, marker.position.latitude);
    maxLat = maxLat == null ? marker.position.latitude : max(maxLat, marker.position.latitude);
    minLng = minLng == null ? marker.position.longitude : min(minLng, marker.position.longitude);
    maxLng = maxLng == null ? marker.position.longitude : max(maxLng, marker.position.longitude);
  }
  
  return LatLngBounds(
    northeast: LatLng(maxLat!, maxLng!),
    southwest: LatLng(minLat!, minLng!),
  );
}



  Widget _buildOfficerItem(
      String badge, String name, String status, String route) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(badge, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'Active'
                            ? Colors.green[100]
                            : Colors.amber[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              color: status == 'Active'
                                  ? Colors.green[800]
                                  : Colors.amber[800],
                              fontSize: 12)),
                    ),
                  ],
                ),
                Text(route,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemsGrid() {
    return Column(
      children: [
        // _buildAlertsCard(),
        // SizedBox(width: 36),
        _buildReportsCard(),
      ],
    );
  }

  Widget _buildAlertsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Recent Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ..._buildAlertList(),
            SizedBox(height: 16),
            TextButton(
              child: Text('View All'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAlertList() {
    return [
      _buildAlertItem('Unauthorized Access', Colors.red, 'Detected at Route B',
          '2 hours ago'),
      _buildAlertItem('Missed Checkpoint', Colors.amber,
          'Detected at Checkpoint 2', '3 hours ago'),
    ];
  }

  Widget _buildAlertItem(
      String alertTitle, Color color, String desc, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alertTitle, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(desc,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                Text(time,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.blue[800],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(Icons.assignment, color: Colors.white, size: 24),
              ],
            ),
            const SizedBox(height: 20),
            ...allReports.take(3).map((report) => Column(
                  children: [
                    _buildReportItem(
                        //TODO classify incident and regular report
                        icon: '📄',
                        title: report["type"],
                        subtitle: 'Submitted by ${report["user"]["name"]}',
                        date: _formatReportDate(report["createdAt"]),
                        onTap: () => {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IncidentReportDetails(
                                    id: report["_id"].toString(),
                                    description: report["description"],
                                    latitude: report["location"]["coordinates"]
                                        [0]["latitude"],
                                    longitude: report["location"]["coordinates"]
                                        [0]["longitude"],
                                    imageUrls: report["images"],
                                    reportDate:
                                        _formatReportDate(report["createdAt"]),
                                    reviewStatus: report["isReviewed"],
                                  ),
                                ),
                              )
                            }),
                    if (allReports.indexOf(report) != allReports.length - 1)
                      Divider(color: Colors.white.withOpacity(0.2)),
                  ],
                )),
            if (allReports.length > 3) const SizedBox(height: 10),
            if (allReports.length > 3)
              Text(
                '+ ${allReports.length - 3} more reports',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                icon: Icon(Icons.list_alt, color: Colors.white),
                label: Text(
                  'View All Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReportsPage(
                              reports: allReports,
                            )),
                  );
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem({
    required String icon,
    required String title,
    required String subtitle,
    required String date,
    required VoidCallback onTap, // Add this parameter
  }) {
    return GestureDetector(
      onTap: onTap, // Use the provided callback
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 20))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              date,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReportDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  Future<void> fetchReport(BuildContext context) async {
    String? token = await TokenHelper.getToken();
    try {
      final response = await http.get(
        Uri.parse('https://patrollingappbackend.onrender.com/api/v1/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          allReports = responseData['data'] ?? [];
          reportsLoaded = true;
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

// class AllReportsPage extends StatelessWidget {
//   final List<dynamic>? reports;
//   const AllReportsPage({super.key, required this.reports});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('All reports')),
//       body: Center(
//           child: Card(
//         color: Colors.blue[800],
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Text('Recent Reports',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white)),
//               SizedBox(height: 16),
//               Column(
//                   // children: reports!.map<Widget>((report) => _buildReportItem('📄', 'report', 'submitted by ${report["user"]["name"]}', '$report["createdAt"]')).toList(),
//                   ),
//               SizedBox(height: 16),
//             ],
//           ),
//         ),
//       )),
//     );
//   }
// }

class IncidentReportDetails extends StatelessWidget {
  final String id;
  final String description;
  final String latitude;
  final String longitude;
  final List<dynamic> imageUrls;
  final String? reportDate;
  final String? status;
  final bool? reviewStatus;

  const IncidentReportDetails({
    super.key,
    required this.id,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.reviewStatus,
    this.reportDate,
    this.status,
  });

Future<Uint8List> _generatePdf() async {
  final pdf = pw.Document();
  final theme = pw.ThemeData.withFont(
    base: await PdfGoogleFonts.openSansRegular(),
    bold: await PdfGoogleFonts.openSansBold(),
  );

  // final File imageFile = File('');
  

  Future<Uint8List> loadAssetImage(String path) async {
  final ByteData data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}
final Uint8List imageBytes = await loadAssetImage( 'assets/logos/up_police_logo.jpeg');

final List<pw.ImageProvider> imageProviders = [];
  for (var imageUrl in imageUrls) {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        imageProviders.add(pw.MemoryImage(response.bodyBytes));
      }
    } catch (e) {
      debugPrint('Error loading image for PDF: $e');
      // Add placeholder for failed images
      imageProviders.add(pw.MemoryImage(Uint8List(0))); // Will be handled in display
    }
  }

  // Main content page
  pdf.addPage(
    pw.Page(
      theme: theme,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with logo (if you have one)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(pw.MemoryImage(imageBytes), width: 100, height: 40),
                pw.Text(
                  'INCIDENT REPORT',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                // Add your logo here if needed
                
              ],
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),

            // Incident Details Section
            pw.Text(
              'Incident Details',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.SizedBox(height: 15),

            // Description
            _buildDetailSection('Description', description),
            pw.SizedBox(height: 15),

            // Location
            pw.Text(
              'Location:',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Latitude: $latitude'),
            pw.Text('Longitude: $longitude'),
            pw.SizedBox(height: 15),

            // Report Date
            _buildDetailSection('Report Date', reportDate ?? 'N/A'),
            pw.SizedBox(height: 15),

            // Status (if available)
            if (status != null) _buildDetailSection('Status', status!),
            pw.SizedBox(height: 25),

            // Add small preview of first image if available
            if (imageProviders.isNotEmpty) ...[
              pw.Text(
                'Incident Images',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.GridView(
                crossAxisCount: 2, // 2 images per row
                childAspectRatio: 3/4, // Width/Height ratio
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: imageProviders.map((provider) {
                  return pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5),),
                    child: provider is pw.MemoryImage && provider.bytes.isEmpty 
                      ? pw.Center(
                          child: pw.Text('Image failed to load',
                            style: const pw.TextStyle(color: PdfColors.red)),
                        )
                      : pw.Image(
                          provider,
                          fit: pw.BoxFit.cover,
                        ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                '* Images are scaled to fit while maintaining aspect ratio',
                style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
            ],
          ],
        );
      },
    ),
  );

  // ******** adding image per page as full pages with proper sizing and metadata
  // if (imageUrls.isNotEmpty) {
  //   for (var i = 0; i < imageUrls.length; i++) {
  //     try {
  //       final response = await http.get(Uri.parse(imageUrls[i]));
  //       if (response.statusCode == 200) {
  //         final image = pw.MemoryImage(response.bodyBytes);

  //         pdf.addPage(
  //           pw.Page(
  //             theme: theme,
  //             margin: const pw.EdgeInsets.all(16),
  //             build: (pw.Context context) {
  //               return pw.Column(
  //                 children: [
  //                   pw.Text(
  //                     'Incident Image ${i + 1}/${imageUrls.length}',
  //                     style: pw.TextStyle(
  //                       fontSize: 12,
  //                       fontWeight: pw.FontWeight.bold,
  //                     ),
  //                   ),
  //                   pw.SizedBox(height: 10),
  //                   pw.Expanded(
  //                     child: pw.Container(
  //                       alignment: pw.Alignment.center,
  //                       child: pw.Image(
  //                         image,
  //                         fit: pw.BoxFit.contain,
  //                       ),
  //                     ),
  //                   ),
  //                   pw.SizedBox(height: 10),
  //                   pw.Text(
  //                     'Image ${i + 1} - ${imageUrls[i]}',
  //                     style: const pw.TextStyle(fontSize: 10),
  //                   ),
  //                 ],
  //               );
  //             },
  //           ),
  //         );
  //       }
  //     } catch (e) {
  //       debugPrint('Error loading image for PDF: $e');
  //       // Add placeholder for failed images
  //       pdf.addPage(
  //         pw.Page(
  //           build: (pw.Context context) {
  //             return pw.Center(
  //               child: pw.Text(
  //                 'Failed to load image ${i + 1}\nURL: ${imageUrls[i]}',
  //                 textAlign: pw.TextAlign.center,
  //               ),
  //             );
  //           },
  //         ),
  //       );
  //     }
  //   }
  // }

  return pdf.save();
}

// Helper function to build consistent detail sections
pw.Widget _buildDetailSection(String title, String content) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '$title:',
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        content,
        style: const pw.TextStyle(fontSize: 12),
      ),
    ],
  );
}

  void _printReport() async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _generatePdf(),
      );
    } catch (e) {
      debugPrint('Error printing PDF: $e');
    }
  }

  void _viewOnMap(BuildContext context) {
    try {
      final lat = double.parse(latitude);
      final lng = double.parse(longitude);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            latitude: lat,
            longitude: lng,
            description: description,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid location coordinates')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Report Details'),
        backgroundColor: const Color(0xff118E13),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and date row
            if (status != null || reportDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status!),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          status!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (reportDate != null)
                      Text(
                        reportDate!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),

            // Location information
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 8),
                        Text('Latitude: $latitude'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 8),
                        Text('Longitude: $longitude'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _viewOnMap(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity,
                            40), // This refers to dart:ui's Size
                      ),
                      child: const Text('View on Map'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(description),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Images section
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (imageUrls.isEmpty) const Text('No images attached'),
                    if (imageUrls.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _showFullScreenImage(context, imageUrls[index]);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CachedNetworkImage(
                                imageUrl: imageUrls[index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                  onPressed: () {

                  if (reviewStatus!) return;
                  _handleStatusUpdate(context, id);
                  },
                  style: OutlinedButton.styleFrom(
                      backgroundColor: reviewStatus == true
                          ? Colors.orange
                          : const Color(0xff118E13),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xff118E13))),
                  child: Text(
                    reviewStatus == true ? 'Reviewed' : 'Mark as Reviewed',
                    style: TextStyle(color: Colors.white),
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleStatusUpdate(BuildContext context, String reportId) {

    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Mark as Reviewed?'),
        content: Text('Are you sure you want to mark this report as Reviewed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReportStatus(context, reportId);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _updateReportStatus(BuildContext context, String reportId) async {
  BuildContext? loadingContext;

  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        loadingContext = context;
        return const Center(child: CircularProgressIndicator());
      },
    );

    String? token = await TokenHelper.getToken();
    if (token == null) {
      _dismissLoading(loadingContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final response = await http.patch(
      Uri.parse('https://patrollingappbackend.onrender.com/api/v1/report/$reportId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'isReviewed': true, // Explicitly set to true since your endpoint seems to only mark as reviewed
      }),
    );

    _dismissLoading(loadingContext);

    // Handle empty response
    if (response.body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report marked as reviewed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate success
      return;
    }

    try {
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Report marked as reviewed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report status updated (malformed response)'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  } catch (e) {
    _dismissLoading(loadingContext);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Network error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _dismissLoading(BuildContext? context) {
  if (context != null && Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            )),
      ),
    );
  }
}
