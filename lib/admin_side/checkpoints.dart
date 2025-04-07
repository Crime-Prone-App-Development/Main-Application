import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckpointsAdminPage extends StatefulWidget {
  const CheckpointsAdminPage({super.key});

  @override
  State<CheckpointsAdminPage> createState() => _CheckpointsAdminPageState();
}

class _CheckpointsAdminPageState extends State<CheckpointsAdminPage> {
  String _selectedFilter = 'all';
  late GoogleMapController _mapController;
  CameraPosition _currentCameraPosition = const CameraPosition(
    target: LatLng(26.511639, 80.230954),
    zoom: 14,
  );

  final List<Map<String, dynamic>> _checkpoints = [
    {
      'id': '1',
      'name': 'Main Entrance',
      'location': '123 Main St',
      'lat': 26.511639,
      'lng': 80.230954,
      'status': 'Active'
    },
    {
      'id': '2',
      'name': 'Parking Lot',
      'location': '456 Park Ave',
      'lat': 26.512500,
      'lng': 80.231500,
      'status': 'Active'
    },
    {
      'id': '3',
      'name': 'Warehouse Area',
      'location': '789 Warehouse Rd',
      'lat': 26.513000,
      'lng': 80.232000,
      'status': 'Inactive'
    },
    {
      'id': '4',
      'name': 'Front Gate',
      'location': '321 Front St',
      'lat': 26.510000,
      'lng': 80.229500,
      'status': 'Active'
    },
  ];
  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  Set<Marker> _markers = {};
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(26.511639, 80.230954),
    zoom: 14,
  );

  List<Map<String, dynamic>> get _filteredCheckpoints {
    return _checkpoints.where((c) {
      final status = c['status']?.toString().toLowerCase().trim();
      if (_selectedFilter == 'active') return status == 'active';
      if (_selectedFilter == 'inactive') return status == 'inactive';
      return true;
    }).toList();
  }

  void _initializeMarkers() {
    _markers = _checkpoints.map((checkpoint) {
      final lat = checkpoint['lat'] as double;
      final lng = checkpoint['lng'] as double;
      return Marker(
        markerId: MarkerId(checkpoint['id']),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: checkpoint['name'],
          snippet: checkpoint['status'],
        ),
        onTap: () {
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 18),
          );
        },
      );
    }).toSet();
  }

  void _openFullScreenMap(BuildContext context) async {
    final updatedPosition = await Navigator.push<CameraPosition>(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMapPage(
          initialPosition: _currentCameraPosition,
          markers: _markers,
        ),
      ),
    );

    if (updatedPosition != null) {
      setState(() {
        _currentCameraPosition = updatedPosition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _checkpoints
        .where((c) => (c['status']?.toString().toLowerCase() ?? '') == 'active')
        .length;
    final inactiveCount = _checkpoints.length - activeCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkpoints'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Name: [Admin Full Name]',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text('Overview Section',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total Checkpoints: ${_checkpoints.length}'),
            Text('Active Checkpoints: $activeCount'),
            Text('Inactive Checkpoints: $inactiveCount'),
            const SizedBox(height: 24),
            const Text('Checkpoints List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Checkpoints',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('All Checkpoints', 'all'),
                _buildFilterChip('Active', 'active'),
                _buildFilterChip('Inactive', 'inactive'),
                _buildFilterChip('Custom Filter', 'custom'),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Checkpoint ID')),
                  DataColumn(label: Text('Checkpoint Name')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _filteredCheckpoints.map((c) {
                  return DataRow(cells: [
                    DataCell(Text(c['id'] ?? '')),
                    DataCell(Text(c['name'] ?? '')),
                    DataCell(Text(c['location'] ?? '')),
                    DataCell(Text(c['status'] ?? '')),
                  ]);
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => _openFullScreenMap(context),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 174, 235, 230),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "Click to view map",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
    );
  }
}

class FullScreenMapPage extends StatefulWidget {
  final CameraPosition initialPosition;
  final Set<Marker> markers;

  const FullScreenMapPage({
    super.key,
    required this.initialPosition,
    required this.markers,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  late GoogleMapController _mapController;
  CameraPosition? _currentPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _currentPosition ?? widget.initialPosition);
          },
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: widget.initialPosition,
        markers: widget.markers,
        zoomControlsEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onCameraMove: (position) {
          _currentPosition = position;
        },
      ),
    );
  }
}
