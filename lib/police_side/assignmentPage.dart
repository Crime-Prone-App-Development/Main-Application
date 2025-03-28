import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mainapp/token_helper.dart';

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
              ? CircularProgressIndicator()
              : Column(
                  children: Assignments.isEmpty
                      ? [Text("No Asssignments Alloted")]
                      : Assignments.map<Widget>((element) {
                          return _modifiedCard(
                            title: 'Assignment',
                            areaName: element['location'][0]['name'] ?? '',
                            startsAt: _parseTime(
                                element['startsAt']?.toString() ?? ''),
                            endsAt:
                                _parseTime(element['endsAt']?.toString() ?? ''),
                            isActive: isPastEndTime(element['endsAt'].toString())
                          );
                        }).toList(),
                ),
        ));
  }

  Widget _modifiedCard({title, areaName, startsAt, endsAt, bool isActive = false}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                          fontWeight: FontWeight.w600,
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

            // Time Badge
            _buildTimeBadge(startsAt, endsAt),
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
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTimeBadge(startsAt, endsAt) {
    // TimeOfDay start = TimeOfDay.fromDateTime(DateTime.parse(startsAt.split(' ')))
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${_formatTime(startsAt)} - ${_formatTime(endsAt)}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
      ),
    );
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      // Parse the ISO 8601 string into a DateTime object
      final dateTime = DateTime.parse(timeString);

      // Extract the hour and minute to create a TimeOfDay object
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      // Return a default TimeOfDay if parsing fails
      return const TimeOfDay(hour: 0, minute: 0);
    } // Default fallback
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
