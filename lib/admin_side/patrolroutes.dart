import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: PatrolRoutesScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class PatrolRoute {
  final int id;
  final String name;
  final List<String> guards;
  final bool isActive;
  final String lastUpdated;

  PatrolRoute({
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

  final List<PatrolRoute> _routes = [
    PatrolRoute(
      id: 1,
      name: 'Main Entrance',
      guards: ['John Doe', 'Jane Smith'],
      isActive: true,
      lastUpdated: '10/15/23',
    ),
    PatrolRoute(
      id: 2,
      name: 'Parking Lot',
      guards: ['Mike Johnson'],
      isActive: true,
      lastUpdated: '10/14/23',
    ),
    PatrolRoute(
      id: 3,
      name: 'Warehouse Area',
      guards: ['Sarah Connor'],
      isActive: false,
      lastUpdated: '10/10/23',
    ),
    PatrolRoute(
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
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 50, color: Colors.grey),
                        Text('Live Patrol Map', style: TextStyle(fontSize: 18)),
                      ],
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
    return GestureDetector(
      onTap: _toggleAddDialog,
      child: SingleChildScrollView(
        child: Container(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent dialog close when tapping inside
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Form(
                  key: _formKey,
                  child: Stack(
                    children: [
                      Column(
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
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map, size: 40, color: Colors.grey),
                                  Text('Route Map Integration'),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          SwitchListTile(
                            title: Text('Active Status'),
                            value: _statusActive,
                            onChanged: (value) =>
                                setState(() => _statusActive = value),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _saveRoute,
                            child: Text('Save Route'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: _toggleAddDialog,
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

  void _saveRoute() {
    if (_formKey.currentState!.validate()) {
      // Add the new route
      setState(() {
        _routes.add(PatrolRoute(
          id: _routes.length + 1,
          name: _nameController.text,
          guards: List.from(_selectedGuards),
          isActive: _statusActive,
          lastUpdated: '${DateTime.now().month}/${DateTime.now().day}',
        ));
      });
      _toggleAddDialog();
    }
  }
}
