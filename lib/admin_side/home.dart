import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mainapp/admin_side/alert.dart';
import 'package:mainapp/admin_side/checkpoints.dart';
import 'package:mainapp/admin_side/patrolroutes.dart';
import 'package:mainapp/admin_side/reports.dart';
import 'package:mainapp/police_side/checkpoint.dart';
import 'package:mainapp/police_side/home.dart';
import '../token_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import './officersTable.dart';
import 'assign.dart';

class adminHome extends StatefulWidget {
  @override
  _adminHomeState createState() => _adminHomeState();
}

class _adminHomeState extends State<adminHome> {
  bool _isSidebarOpen = false;
  final double _sidebarWidth = 200.0;
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
      child: ListView(
        padding: EdgeInsets.only(top: 20, left: 8),
        children: [
          _buildMenuItem('Dashboard', Icons.dashboard, adminHome()),
          _buildMenuItem('Patrol Routes', Icons.map, PatrolRoutesScreen()),
          _buildMenuItem('Assign Police Officers', Icons.people, AdminApp()),
          _buildMenuItem('Reports', Icons.assignment, ReportsPage()),
          _buildMenuItem('Alerts', Icons.warning, AlertsScreen()),
          _buildMenuItem('Checkpoints', Icons.flag, CheckpointsAdminPage()),
        ],
      ),
    );
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
            'Active Police Officers', '50', Icons.people, Colors.blue),
        _buildStatCard('Active Routes', '25', Icons.map, Colors.purple),
        _buildStatCard('Alerts Today', '10', Icons.warning, Colors.red),
        _buildStatCard(
            'Completion Rate', '95%', Icons.check_circle, Colors.green),
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
        InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenRouteMap(routes: _routes),
                ));
          },
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 174, 235, 230),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "Click to view all patrol routes on map",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        _buildOfficersCard()
      ],
    );
  }

  Widget _buildOfficersCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Active Officers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ..._buildOfficerList(),
            SizedBox(height: 16),
            TextButton(
              child: Text('View All Police Officers'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOfficerList() {
    return [
      _buildOfficerItem('A1', 'Police Officer 1', 'Active', 'Route A'),
      _buildOfficerItem('A2', 'Police Officer 2', 'Active', 'Route B'),
      _buildOfficerItem('A3', 'Police Officer 3', 'Break', 'Route C'),
      _buildOfficerItem('B1', 'Police Officer 4', 'Active', 'Route D'),
    ];
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
        _buildAlertsCard(),
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

  Widget _buildAlertItem(String title, Color color, String desc, String time) {
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
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
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
      color: Colors.blue[800],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Recent Reports',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 16),
            ..._buildReportList(),
            SizedBox(height: 16),
            TextButton(
              child: Text('View All', style: TextStyle(color: Colors.white)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReportList() {
    return [
      _buildReportItem('📄', 'Daily Patrol Report',
          'Submitted by <Police Officer 1>', 'Today, 8:00 AM'),
      Divider(color: Colors.white54, height: 24),
      _buildReportItem('📄', 'Incident Report #2222',
          'Submitted by <Police Officer 4>', 'Yesterday, 12:45 AM'),
    ];
  }

  Widget _buildReportItem(
      String emoji, String title, String author, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(emoji, style: TextStyle(fontSize: 20)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                Text(author,
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(time,
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
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
        print(responseData);
      }
    } catch (e) {
      // Handle any errors that occur during the request
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }
}
