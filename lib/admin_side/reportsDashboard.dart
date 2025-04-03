import 'package:flutter/material.dart';

class ReportsDashboard extends StatelessWidget {
  final String adminName = "Admin Full Name"; // Replace with dynamic data
  final int totalReports = 125; // Replace with dynamic data
  final int pendingReports = 42; // Replace with dynamic data
  final int reviewedReports = 83; // Replace with dynamic data

  final List<Map<String, dynamic>> reports = [
    {
      'id': 1,
      'guardName': 'John Doe',
      'date': '10/15/2023',
      'type': 'Incident Report',
      'status': 'Pending'
    },
    {
      'id': 2,
      'guardName': 'Jane Smith',
      'date': '10/14/2023',
      'type': 'Daily Patrol Report',
      'status': 'Reviewed'
    },
    {
      'id': 3,
      'guardName': 'Mike Johnson',
      'date': '10/13/2023',
      'type': 'Incident Report',
      'status': 'Pending'
    },
    {
      'id': 4,
      'guardName': 'Sarah Connor',
      'date': '10/12/2023',
      'type': 'Equipment Report',
      'status': 'Reviewed'
    },
    // Add more reports as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              // Implement filter functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Info
            Text(
              'Admin Name: $adminName',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Overview Section
            const Text(
              'Overview Section',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('Total Reports', totalReports.toString(), Colors.blue),
                _buildStatCard('Pending Reports', pendingReports.toString(), Colors.orange),
                _buildStatCard('Reviewed Reports', reviewedReports.toString(), Colors.green),
              ],
            ),
            const SizedBox(height: 24),

            // Reports List Section
            const Text(
              'Reports List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Reports',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Reports', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Reviewed', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Custom Filter', false),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reports Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Report ID')),
                  DataColumn(label: Text('Guard Name')),
                  DataColumn(label: Text('Date Submitted')),
                  DataColumn(label: Text('Report Type')),
                  DataColumn(label: Text('Status')),
                ],
                rows: reports.map((report) {
                  return DataRow(
                    cells: [
                      DataCell(Text(report['id'].toString())),
                      DataCell(Text(report['guardName'])),
                      DataCell(Text(report['date'])),
                      DataCell(Text(report['type'])),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: report['status'] == 'Pending'
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            report['status'],
                            style: TextStyle(
                              color: report['status'] == 'Pending'
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onSelectChanged: (selected) {
                      // Navigate to report details
                      _navigateToReportDetails(context, report['id']);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool value) {
        // Implement filter selection
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: selected ? Colors.blue : Colors.black,
      ),
    );
  }

  void _navigateToReportDetails(BuildContext context, int reportId) {
    // Implement navigation to report details page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(reportId: reportId),
      ),
    );
  }
}

// Placeholder for report details screen
class ReportDetailsScreen extends StatelessWidget {
  final int reportId;

  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report #$reportId Details'),
      ),
      body: Center(
        child: Text('Details for report $reportId'),
      ),
    );
  }
}