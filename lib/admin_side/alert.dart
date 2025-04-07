import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: AlertsScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class Alert {
  final int id;
  final String type;
  final DateTime date;
  final String guard;
  final bool isActive;

  Alert({
    required this.id,
    required this.type,
    required this.date,
    required this.guard,
    required this.isActive,
  });

  String get formattedDate =>
      '${date.month}/${date.day}/${date.year.toString().substring(2)}';
}

class AlertsScreen extends StatefulWidget {
  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _currentFilter = 'All';
  final List<Alert> _alerts = [
    Alert(
      id: 1,
      type: 'Security Breach',
      date: DateTime(2023, 10, 15),
      guard: 'John D',
      isActive: true,
    ),
    Alert(
      id: 2,
      type: 'Suspicious Activity',
      date: DateTime(2023, 10, 14),
      guard: 'Jane S',
      isActive: true,
    ),
    Alert(
      id: 3,
      type: 'Equipment Failure',
      date: DateTime(2023, 10, 13),
      guard: 'Mike JC',
      isActive: false,
    ),
    Alert(
      id: 4,
      type: 'Incident Report',
      date: DateTime(2023, 10, 12),
      guard: 'Sarah C',
      isActive: false,
    ),
  ];

  List<Alert> get _filteredAlerts {
    switch (_currentFilter) {
      case 'Active':
        return _alerts.where((alert) => alert.isActive).toList();
      case 'Resolved':
        return _alerts.where((alert) => !alert.isActive).toList();
      default:
        return _alerts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Name: [Admin Full Name]',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 20),

            // Overview Cards
            _buildOverviewCards(),
            SizedBox(height: 20),

            // Filter Chips
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Active'),
                _buildFilterChip('Resolved'),
                _buildFilterChip('Custom Filter'),
              ],
            ),
            SizedBox(height: 16),

            // Alerts Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: [
                  DataColumn(label: Text('Alert ID')),
                  DataColumn(label: Text('Alert Type')),
                  DataColumn(label: Text('Date Submitted')),
                  DataColumn(label: Text('Guard')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _filteredAlerts
                    .map((alert) => DataRow(
                          cells: [
                            DataCell(Text(alert.id.toString())),
                            DataCell(Text(alert.type)),
                            DataCell(Text(alert.formattedDate)),
                            DataCell(Text(alert.guard)),
                            DataCell(
                              Chip(
                                label: Text(
                                    alert.isActive ? 'Active' : 'Resolved'),
                                backgroundColor: alert.isActive
                                    ? Colors.orange[100]
                                    : Colors.green[100],
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        _buildInfoCard('Total Alerts', _alerts.length.toString()),
        _buildInfoCard('Active Alerts',
            _alerts.where((a) => a.isActive).length.toString()),
        _buildInfoCard('Resolved Alerts',
            _alerts.where((a) => !a.isActive).length.toString()),
      ],
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _currentFilter == label,
      onSelected: (selected) {
        if (selected) {
          setState(() => _currentFilter = label);
        }
      },
      selectedColor: Colors.blue[200],
      labelStyle: TextStyle(
        color: _currentFilter == label ? Colors.black : Colors.grey,
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Alerts'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Search by type, guard, or ID...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement search logic
              Navigator.pop(context);
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }
}
