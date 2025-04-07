import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reports App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ReportsPage(),
    );
  }
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedFilter = 'all';
  final List<Map<String, dynamic>> _reports = [
    {
      'id': '1',
      'guard': 'John Doe',
      'date': '10/15/2023',
      'type': 'Incident Report',
      'status': 'Pending'
    },
    {
      'id': '2',
      'guard': 'Jane Smith',
      'date': '10/14/2023',
      'type': 'Daily Patrol Report',
      'status': 'Reviewed'
    },
    {
      'id': '3',
      'guard': 'Mike Johnson',
      'date': '10/13/2023',
      'type': 'Incident Report',
      'status': 'Pending'
    },
    {
      'id': '4',
      'guard': 'Sarah Connor',
      'date': '10/12/2023',
      'type': 'Equipment Report',
      'status': 'Reviewed'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Name: [Admin Full Name]',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Overview Section',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Total Reports: 4'),
            const Text('Pending Reports: 2'),
            const Text('Reviewed Reports: 2'),
            const SizedBox(height: 24),
            const Text(
              'Reports List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Reports',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Reports', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Reviewed', 'reviewed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Custom Filter', 'custom'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(
                          label: Text('Report ID',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Guard Name',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Date Submitted',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Report Type',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _reports
                        .map((report) => DataRow(
                              cells: [
                                DataCell(Text(report['id'])),
                                DataCell(Text(report['guard'])),
                                DataCell(Text(report['date'])),
                                DataCell(Text(report['type'])),
                                DataCell(Text(report['status'])),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              );
            }),
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
