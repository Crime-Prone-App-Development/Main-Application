import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// void main() {
//   runApp(MaterialApp(
//     home: PatrolRoutesScreen(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

class PatrolRoute {
  final int id;
  final String name;
  final List<String> guards;
  final bool isActive;
  final String lastUpdated;
  final LatLng position;
  PatrolRoute({
    required this.position,
    required this.id,
    required this.name,
    required this.guards,
    required this.isActive,
    required this.lastUpdated,
  });
}

class PatrolRoutesScreen extends StatefulWidget {
  @override
  _PatrolRoutesScreenState createState() => _PatrolRoutesScreenState();
}

class _PatrolRoutesScreenState extends State<PatrolRoutesScreen> {
  bool _showAddDialog = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  List<String> _selectedGuards = [];
  bool _statusActive = true;
  String _filter = 'All';
  LatLng? _selectedPosition; // To store selected map position
  late GoogleMapController _mapController;
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

  List<PatrolRoute> get _filteredRoutes {
    if (_filter == 'Active') {
      return _routes.where((route) => route.isActive).toList();
    } else if (_filter == 'Inactive') {
      return _routes.where((route) => !route.isActive).toList();
    }
    return _routes;
  }

  Widget _buildMapSection() {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _routes.isNotEmpty
                  ? _routes.first.position
                  : LatLng(26.511639, 80.230954),
              zoom: 14,
            ),
            markers: _routes
                .map((route) => Marker(
                      markerId: MarkerId(route.id.toString()),
                      position: route.position,
                      infoWindow: InfoWindow(title: route.name),
                    ))
                .toSet(),
            onTap: (LatLng position) {
              setState(() {
                _selectedPosition = position;
              });
            },
            onMapCreated: (controller) => _mapController = controller,
          ),
        ),
        SizedBox(height: 10),
        if (_selectedPosition != null)
          Text(
              'Selected Position: ${_selectedPosition!.latitude.toStringAsFixed(4)}, '
              '${_selectedPosition!.longitude.toStringAsFixed(4)}'),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            final position = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenMapPicker(
                  initialPosition: _selectedPosition ??
                      (_routes.isNotEmpty
                          ? _routes.first.position
                          : LatLng(26.511639, 80.230954)),
                ),
              ),
            );
            if (position != null) {
              setState(() => _selectedPosition = position);
            }
          },
          child: Text('Select Position on Map'),
        ),
      ],
    );
  }

  void _saveRoute() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a position on the map')));
        return;
      }

      setState(() {
        _routes.add(PatrolRoute(
          id: _routes.length + 1,
          name: _nameController.text,
          guards: List.from(_selectedGuards),
          isActive: _statusActive,
          lastUpdated: '${DateTime.now().month}/${DateTime.now().day}',
          position: _selectedPosition!,
        ));
      });
      _toggleAddDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patrol Routes'),
        actions: [
          IconButton(icon: Icon(Icons.import_export), onPressed: () {}),
          IconButton(icon: Icon(Icons.file_download), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Name: [Admin Full Name]',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),

                // Overview Cards
                Row(
                  children: [
                    _buildInfoCard('Total Routes', _routes.length.toString()),
                    _buildInfoCard('Active Routes',
                        _routes.where((r) => r.isActive).length.toString()),
                    _buildInfoCard('Inactive Routes',
                        _routes.where((r) => !r.isActive).length.toString()),
                  ],
                ),
                SizedBox(height: 20),

                // Filter Buttons
                Row(
                  children: [
                    _buildFilterButton('All', _filter == 'All'),
                    _buildFilterButton('Active', _filter == 'Active'),
                    _buildFilterButton('Inactive', _filter == 'Inactive'),
                    Spacer(),
                    // _buildFilterButton('Custom Filter', false),
                  ],
                ),
                SizedBox(height: 10),

                // Routes Table
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Route ID')),
                      DataColumn(label: Text('Route Name')),
                      DataColumn(label: Text('Assigned Guards')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Last Updated')),
                    ],
                    rows: _filteredRoutes.map((route) {
                      return DataRow(cells: [
                        DataCell(Text(route.id.toString())),
                        DataCell(Text(route.name)),
                        DataCell(Text(route.guards.join(', '))),
                        DataCell(
                          Chip(
                            label: Text(route.isActive ? 'Active' : 'Inactive'),
                            backgroundColor: route.isActive
                                ? Colors.green[100]
                                : Colors.red[100],
                          ),
                        ),
                        DataCell(Text(route.lastUpdated)),
                      ]);
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),

                // Map Placeholder
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FullScreenRouteMap(routes: _routes),
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
                SizedBox(height: 20),
              ],
            ),
          ),

          // Add Route Dialog
          if (_showAddDialog) _buildAddDialog(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAddDialog,
        child: Icon(Icons.add),
        tooltip: 'Add New Patrol Route',
      ),
    );
  }

  Widget _buildAddDialog() {
    return InkWell(
      onTap: _toggleAddDialog,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dialog close when tapping inside
            child: Container(
              height: MediaQuery.of(context).size.height / 1.3,
              width: MediaQuery.of(context).size.width * 0.9,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add New Patrol Route',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Route Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Assigned Guards',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'John Doe',
                          'Jane Smith',
                          'Mike Johnson',
                          'Sarah Connor'
                        ]
                            .map((guard) => DropdownMenuItem(
                                  value: guard,
                                  child: Text(guard),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null &&
                              !_selectedGuards.contains(value)) {
                            setState(() => _selectedGuards.add(value));
                          }
                        },
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Route Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 15),
                      SwitchListTile(
                        title: Text('Active Status'),
                        value: _statusActive,
                        onChanged: (value) =>
                            setState(() => _statusActive = value),
                      ),
                      SizedBox(height: 10),
                      _buildMapSection(), // Add the map section here
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: _saveRoute,
                        child: Text('Save Route'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 8),
              Text(value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (selected) _filter = text;
          });
        },
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  void _toggleAddDialog() {
    setState(() {
      _showAddDialog = !_showAddDialog;
      if (!_showAddDialog) {
        _nameController.clear();
        _descriptionController.clear();
        _selectedGuards.clear();
        _statusActive = true;
      }
    });
  }

  // void _saveRoute() {
  //   if (_formKey.currentState!.validate()) {
  //     // Add the new route
  //     setState(() {
  //       _routes.add(PatrolRoute(
  //         id: _routes.length + 1,
  //         name: _nameController.text,
  //         guards: List.from(_selectedGuards),
  //         isActive: _statusActive,
  //         lastUpdated: '${DateTime.now().month}/${DateTime.now().day}',
  //       ));
  //     });
  //     _toggleAddDialog();
  //   }
  // }
}

class FullScreenMapPicker extends StatefulWidget {
  final LatLng initialPosition;

  const FullScreenMapPicker({required this.initialPosition});

  @override
  _FullScreenMapPickerState createState() => _FullScreenMapPickerState();
}

class _FullScreenMapPickerState extends State<FullScreenMapPicker> {
  late GoogleMapController _mapController;
  LatLng? _selectedPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Route Position'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              if (_selectedPosition != null) {
                Navigator.pop(context, _selectedPosition);
              }
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialPosition,
          zoom: 14,
        ),
        onTap: (position) {
          setState(() => _selectedPosition = position);
        },
        markers: _selectedPosition != null
            ? {
                Marker(
                  markerId: MarkerId('selected_position'),
                  position: _selectedPosition!,
                )
              }
            : {},
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}

class FullScreenRouteMap extends StatelessWidget {
  final List<PatrolRoute> routes;

  const FullScreenRouteMap({required this.routes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patrol Routes Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: routes.isNotEmpty
              ? routes.first.position
              : LatLng(26.511639, 80.230954),
          zoom: 14,
        ),
        markers: routes
            .map((route) => Marker(
                  markerId: MarkerId(route.id.toString()),
                  position: route.position,
                  infoWindow: InfoWindow(
                    title: route.name,
                    snippet:
                        'Status: ${route.isActive ? "Active" : "Inactive"}',
                  ),
                ))
            .toSet(),
      ),
    );
  }
}
