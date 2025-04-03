import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mainapp/token_helper.dart';
import 'package:intl/intl.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({Key? key}) : super(key: key);

  @override
  _AssignmentPageState createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  List<dynamic> Assignments = [];
  bool AssignmentLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchAssignments(context);
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Assignment Page'),
    ),
    body: SingleChildScrollView(
      child: !AssignmentLoaded
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      "Loading assignments...",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: Assignments.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "No Assignments Allocated",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    ]
                  : Assignments.map<Widget>((element) {
                      final startDate = DateTime.tryParse(element['startsAt']?.toString() ?? '');
                      final endDate = DateTime.tryParse(element['endsAt']?.toString() ?? '');
                      
                      return _modifiedCard(
                        title: 'Assignment',
                        areaName: element['area']["name"] ?? '',
                        startDate: startDate,
                        endDate: endDate,
                        isActive: isPastEndTime(element['endsAt'].toString()),
                      );
                    }).toList(),
            ),
    ),
  );
}

Widget _modifiedCard({
  required String title,
  required String areaName,
  required DateTime? startDate,
  required DateTime? endDate,
  bool isActive = false,
}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    areaName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[800],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Date and Time Badge
            if (startDate != null && endDate != null) 
              _buildDateTimeBadge(startDate, endDate),
            const SizedBox(height: 12),

            
          ],
        ),
      ),
    ),
  );
}

Widget _buildDateTimeBadge(DateTime startsAt, DateTime endsAt) {
  final isSameDay = startsAt.year == endsAt.year &&
      startsAt.month == endsAt.month &&
      startsAt.day == endsAt.day;

  final dateText = isSameDay
      ? DateFormat('MMM d, yyyy').format(startsAt)
      : '${DateFormat('MMM d').format(startsAt)} - ${DateFormat('MMM d, yyyy').format(endsAt)}';

  final startTime = DateFormat('h:mm a').format(startsAt);
  final endTime = DateFormat('h:mm a').format(endsAt);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue[100] ?? Colors.blue, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.blue[800]),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$dateText • $startTime - $endTime',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
          ),
        ),
      ],
    ),
  );
}

  bool isPastEndTime(String endsAtString) {
    try {
      // Parse the ISO 8601 string into a DateTime object
      final endsAtDateTime = DateTime.parse(endsAtString);

      // Compare with the current time
      return endsAtDateTime.isBefore(DateTime.now());
    } catch (e) {
      // If parsing fails, assume the time is not in the past
      return false;
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> fetchAssignments(BuildContext context) async {
    String? token = await TokenHelper.getToken();
    try {
      final response = await http.get(
        Uri.parse('https://patrollingappbackend.onrender.com/api/v1/assignments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          Assignments = responseData['data'] ?? [];
          AssignmentLoaded = true;
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
