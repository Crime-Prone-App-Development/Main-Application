import 'package:flutter/material.dart';
import 'package:mainapp/token_helper.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReportsPage extends StatefulWidget {
  final List<dynamic>? reports;
  const ReportsPage({Key? key, this.reports}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String adminName = '';
  List<dynamic> reports = [];
  List<dynamic> filteredReports = [];

  // Filtering variables
  String searchQuery = '';
  String statusFilter = 'All';
  DateTimeRange? dateRange;

  // Statistics
  int totalReports = 0;
  int pendingReports = 0;
  int reviewedReports = 0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    reports = widget.reports ?? [];
    filteredReports = List.from(reports);
    _calculateStatistics();

      _fetchReports();
    

    TokenHelper.getUserData().then((userData) {
      setState(() {
        adminName = userData[2] ?? '';
      });
    });
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? token = await TokenHelper.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${dotenv.env["BACKEND_URI"]}/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          reports = responseData['data'] ?? [];
          filteredReports = List.from(reports);
          _calculateStatistics();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch reports'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calculateStatistics() {
    setState(() {
      totalReports = reports.length;
      pendingReports = reports.where((r) => r['isReviewed'] == false).length;
      reviewedReports = reports.where((r) => r['isReviewed'] == true).length;
    });
  }

  String _formatReportDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('y MMM d, h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  String _shortenId(String id) {
    if (id.length <= 6) return id;
    return '${id.substring(0, 3)}...${id.substring(id.length - 3)}';
  }

  void _applyFilters() {
    setState(() {
      filteredReports = reports.where((report) {
        // Search filter
        final matchesSearch = report['user']['name']
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            report['_id']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            report['type']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase());

        // Status filter - now properly checks isReviewed
        final matchesStatus = statusFilter == 'All' ||
            (statusFilter == 'Reviewed' && report['isReviewed'] == true) ||
            (statusFilter == 'Pending' && report['isReviewed'] == false);

        // Date range filter
        bool matchesDate = true;
        if (dateRange != null) {
          try {
            final reportDate = DateTime.parse(report['createdAt']);
            matchesDate = reportDate.isAfter(dateRange!.start) &&
                reportDate.isBefore(dateRange!.end);
          } catch (e) {
            matchesDate = false;
          }
        }

        return matchesSearch && matchesStatus && matchesDate;
      }).toList();

      // Update statistics for the filtered reports - now using isReviewed
      totalReports = filteredReports.length;
      pendingReports =
          filteredReports.where((r) => r['isReviewed'] == false).length;
      reviewedReports =
          filteredReports.where((r) => r['isReviewed'] == true).length;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: dateRange,
    );

    if (picked != null) {
      setState(() {
        dateRange = picked;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReports, // Add this
            tooltip: 'Refresh reports',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Filter Reports',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Status Filter
                            DropdownButtonFormField<String>(
                              value: statusFilter,
                              items: ['All', 'Pending', 'Reviewed']
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  statusFilter = value!;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Date Range Filter
                            ListTile(
                              title: const Text('Date Range'),
                              subtitle: Text(dateRange == null
                                  ? 'Select date range'
                                  : '${DateFormat('MMM d, y').format(dateRange!.start)} - ${DateFormat('MMM d, y').format(dateRange!.end)}'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _selectDateRange(context),
                            ),
                            const SizedBox(height: 16),

                            // Apply Filters Button
                            ElevatedButton(
                              onPressed: () {
                                _applyFilters();
                                Navigator.pop(context);
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
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
                _buildStatCard(
                    'Total Reports', totalReports.toString(), Colors.blue),
                _buildStatCard('Pending Reports', pendingReports.toString(),
                    Colors.orange),
                _buildStatCard('Reviewed Reports', reviewedReports.toString(),
                    Colors.green),
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
                hintText: 'Search by Officer or Report Type',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Reports', statusFilter == 'All', () {
                    setState(() {
                      statusFilter = 'All';
                      _applyFilters();
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', statusFilter == 'Pending', () {
                    setState(() {
                      statusFilter = 'Pending';
                      _applyFilters();
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Reviewed', statusFilter == 'Reviewed', () {
                    setState(() {
                      statusFilter = 'Reviewed';
                      _applyFilters();
                    });
                  }),
                  if (dateRange != null) ...[
                    const SizedBox(width: 8),
                    _buildFilterChip('Date Range', true, () {
                      _selectDateRange(context);
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reports Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('Report ID')),
                  DataColumn(label: Text('Officer Name')),
                  DataColumn(label: Text('Date Submitted')),
                  DataColumn(label: Text('Report Type')),
                  DataColumn(label: Text('Status')),
                ],
                rows: filteredReports.map((report) {
                  return DataRow(
                    cells: [
                      DataCell(Text(_shortenId(report["_id"].toString()))),
                      DataCell(Text(report['user']['name'])),
                      DataCell(Text(_formatReportDate(report['createdAt']))),
                      DataCell(Text(report['type'] ?? "Not defined")),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: !report['isReviewed']
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            report['isReviewed'] ? "Reviewed" : "Pending",
                            style: TextStyle(
                              color: !report['isReviewed']
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onSelectChanged: (selected) {
                      if (selected == true) {
                        _navigateToReportDetails(context, report);
                        _fetchReports();
                      }
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

  Widget _buildFilterChip(
      String label, bool selected, VoidCallback onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool value) => onSelected(),
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: selected ? Colors.blue : Colors.black,
      ),
    );
  }

  void _navigateToReportDetails(BuildContext context, dynamic report) async{
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentReportDetails(
          id: report["_id"].toString(),
          description: report["description"],
          type : report["type"],
          // latitude: report["location"]["coordinates"][0]["latitude"],
          // longitude: report["location"]["coordinates"][0]["longitude"],
          latitude: report["location"][0].toString(),
          longitude: report["location"][1].toString(),
          imageUrls: report["images"],
          reportDate: _formatReportDate(report["createdAt"]),
          reviewStatus: report["isReviewed"],
        ),
      ),
    );
    await _fetchReports();
  }
}
