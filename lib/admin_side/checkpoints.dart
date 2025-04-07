import 'package:flutter/material.dart';

class CheckpointsAdminPage extends StatefulWidget {
  const CheckpointsAdminPage({super.key});

  @override
  State<CheckpointsAdminPage> createState() => _CheckpointsAdminPageState();
}

class _CheckpointsAdminPageState extends State<CheckpointsAdminPage> {
  String _selectedFilter = 'all';
  final List<Map<String, dynamic>> _checkpoints = [
    {
      'id': '1',
      'name': 'Main Entrance',
      'location': '123 Main St',
      'status': 'Active'
    },
    {
      'id': '2',
      'name': 'Parking Lot',
      'location': '456 Park Ave',
      'status': 'Active'
    },
    {
      'id': '3',
      'name': 'Warehouse Area',
      'location': '789 Warehouse Rd',
      'status': 'Inactive'
    },
    {
      'id': '4',
      'name': 'Front Gate',
      'location': '321 Front St',
      'status': 'Active'
    },
  ];

  List<Map<String, dynamic>> get _filteredCheckpoints {
    return _checkpoints.where((c) {
      final status = c['status']?.toString().toLowerCase().trim();
      if (_selectedFilter == 'active') return status == 'active';
      if (_selectedFilter == 'inactive') return status == 'inactive';
      return true;
    }).toList();
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
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('Live Patrol Map'),
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
