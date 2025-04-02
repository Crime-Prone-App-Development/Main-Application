import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../token_helper.dart';
import 'package:http/http.dart' as http;
import './officersTable.dart';

void main() {
  runApp(AdminApp());
}

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminPage(),
    );
  }
}

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String selectedArea = "";
  List<dynamic> areas = [];
  List<dynamic> officers = [];
  List<String> officerIds = [];
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

@override
  void initState() {
    super.initState();
    getAllAreas(context);
  }
  void _removeOfficer(String name) {
    setState(() {
      officers.removeWhere((officer) => officer["name"] == name);
    });
  }

  void _updateOfficerIds() {
    setState(() {
      officerIds = officers.map((officer) => officer["_id"].toString()).toList();
    });
  }

  Future<void> getAllAreas(BuildContext context) async {
    String? token = await TokenHelper.getToken();
    try {
      final response = await http.get(
        Uri.parse('https://patrollingappbackend.onrender.com/api/v1/crime-areas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      );
      print(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        setState(() {
          areas = responseData['data']?.map((officer) => officer["_id"].toString()).toList() ?? [];
          });

      }
    } catch (e) {
      // Handle any errors that occur during the request
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again. $e')),
      );
    }
  }

  Future<void> assignWork(BuildContext context) async {
    _updateOfficerIds();

    if (officers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one officer')),
    );
    return;
  }

  if (selectedArea.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select an area')),
    );
    return;
  }

  if (_startTimeController.text.isEmpty || _endTimeController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter start and end times')),
    );
    return;
  }
    String? token = await TokenHelper.getToken();
    try {
      final response = await http.post(
          Uri.parse(
              'https://patrollingappbackend.onrender.com/api/v1/assignments'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${token}'
          },
          body: json.encode({
            'officerIds': officerIds,
            'startsAt': _startTimeController.text,
            'endsAt': _endTimeController.text,
            'location': selectedArea,
          }));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // final Map<String, dynamic> responseData = json.decode(response.body);
        print("success");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assignment created successfully!')),
        );
        // Clear the form after successful submission
        setState(() {
          officers.clear();
          selectedArea = "";
          _startTimeController.clear();
          _endTimeController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create assignment: ${response.body}')),
        );
      }
    } catch (e) {
      // Handle any errors that occur during the request
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again. $e')),
      );
    }
  }

  Future<void> _navigateAndDisplaySelection(BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => OfficersTablePage(
                initialSelectedOfficers: officers,
              )),
    );

    // When a BuildContext is used from a StatefulWidget, the mounted property
    // must be checked after an asynchronous gap.
    if (!context.mounted) return;

    // After the Selection Screen returns a result, hide any previous snackbars
    // and show the new result.
    setState(() {
      officers = result;
    });
  }
  Future<void> _selectDateTime(BuildContext context, TextEditingController controller) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );
  if (pickedDate != null) {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      final DateTime fullDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      controller.text = fullDateTime.toIso8601String(); // Or format as needed
    }
  }
}

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Work Assignment"),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 1, 32, 96),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Assignment Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildOfficerSelection(),
                    SizedBox(height: 16),
                    _buildDateTimeFields(),
                    SizedBox(height: 16),
                    _buildAreaDropdown(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => assignWork(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "CREATE ASSIGNMENT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Officers",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  officers.isEmpty ? "No officers selected" : "${officers.length} officers selected",
                  style: TextStyle(
                    color: officers.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () {
                _navigateAndDisplaySelection(context);
              },
              icon: Icon(Icons.add, color : Colors.white ,size: 20),
              label: Text("Add", style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (officers.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: officers.map((officer) {
              return Chip(
                label: Text(
                  officer["name"] ?? "Unknown",
                  style: TextStyle(color: Colors.white),
                ),
                deleteIcon: Icon(Icons.close, size: 18, color: Colors.white),
                onDeleted: () => _removeOfficer(officer["name"]),
                backgroundColor: Colors.blue.shade600,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Schedule",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateTimeField(
                controller: _startTimeController,
                label: "Start Time",
                icon: Icons.access_time,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDateTimeField(
                controller: _endTimeController,
                label: "End Time",
                icon: Icons.access_time,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(icon),
        hintText: "Select date & time",
      ),
      readOnly: true,
      onTap: () => _selectDateTime(context, controller),
    );
  }

  Widget _buildAreaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Area",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField(
          decoration: InputDecoration(
            labelText: "Select area",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.location_on),
          ),
          value: selectedArea.isNotEmpty ? selectedArea : null,
          items: areas.map((area) {
            return DropdownMenuItem(
              value: area,
              child: Text(area),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedArea = value as String;
            });
          },
          validator: (value) => value == null ? 'Please select an area' : null,
        ),
      ],
    );
  }
}
