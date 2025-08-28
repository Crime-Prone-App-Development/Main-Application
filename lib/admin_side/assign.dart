import 'package:flutter/material.dart';
import 'package:mainapp/mapPointSelector.dart';
import 'dart:async';
import 'dart:convert';
import '../token_helper.dart';
import 'package:http/http.dart' as http;
import './officersTable.dart';
// import '../addressCoordinates.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// void main() {
//   runApp(AdminApp());
// }

// class AdminApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: AdminPage(),
//     );
//   }
// }

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

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

  final TextEditingController _durationController = TextEditingController();
  LatLng? selectedLocation;

  List<LatLng> selectedLocations = [];

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _removeOfficer(String name) {
    setState(() {
      officers.removeWhere((officer) => officer["name"] == name);
    });
  }

  void _removeLocation(String Lat, String Long) {
    setState(() {
      selectedLocations.removeWhere((loc) =>
          loc.latitude.toString() == Lat && loc.longitude.toString() == Long);
    });
  }

  void _updateOfficerIds() {
    setState(() {
      officerIds =
          officers.map((officer) => officer["_id"].toString()).toList();
    });
  }
  // Future<void> _searchLocation() async {
  //   setState(() {
  //     _isLoading = true;
  //     _coordinates = null;
  //   });

  //   final coordinates = await _locationService.getCoordinates(_newAreaNameController.text);

  //   setState(() {
  //     _coordinates = coordinates;
  //     _isLoading = false;
  //   });
  // }
//   Future<void> _showAddAreaDialog(BuildContext context) async {
//   return showDialog(
//     context: context,
//     builder: (dialogContext) {
//       return AlertDialog(
//         title: Text("Add New Area"),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: _newAreaNameController,
//                 decoration: InputDecoration(
//                   labelText: "Area Name",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: _newAreaDescriptionController,
//                 decoration: InputDecoration(
//                   labelText: "Description",
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 3,
//               ),
//               SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _crimeRateValue,
//                 decoration: InputDecoration(
//                   labelText: "Crime Rate",
//                   border: OutlineInputBorder(),
//                 ),
//                 items: [
//                   DropdownMenuItem(
//                     value: 'low',
//                     child: Text("Low"),
//                   ),
//                   DropdownMenuItem(
//                     value: 'medium',
//                     child: Text("Medium"),
//                   ),
//                   DropdownMenuItem(
//                     value: 'high',
//                     child: Text("High"),
//                   ),
//                 ],
//                 onChanged: (value) {
//                   setState(() {
//                     _crimeRateValue = value;
//                   });
//                 },
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (_newAreaNameController.text.isEmpty) {
//                 scaffoldMessengerKey.currentState?.showSnackBar(
//                   SnackBar(content: Text('Please enter area name')),
//                 );
//                 return;
//               }

//               // await _createNewArea(dialogContext);
//               if (dialogContext.mounted) {
//                 Navigator.pop(dialogContext);
//               }
//             },
//             child: Text("Add Area"),
//           ),
//         ],
//       );
//     },
//   );
// }
// // Future<void> _createNewArea(BuildContext context) async {
//   if (!mounted) return;

//   String? token = await TokenHelper.getToken();
//   // await _searchLocation();
//   // print(_coordinates);

//   if (!mounted) return;

//   if (_coordinates == null) {
//     scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(content: Text('Could not find coordinates for this location')),
//     );
//     return;
//   }

//   try {
//     final response = await http.post(
//       Uri.parse('https://patrollingappbackend.onrender.com/api/v1/crime-areas'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token'
//       },
//       body: json.encode({
//         'name': _newAreaNameController.text,
//         'description': _newAreaDescriptionController.text,
//         'areaType': "Point",
//         'long': _coordinates!.longitude.toString(),
//         'lat': _coordinates!.latitude.toString(),
//         'crimeRate': _crimeRateValue,
//       }),
//     );

//     print(response.body);

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final responseData = json.decode(response.body);
//       if (mounted) {
//         setState(() {
//           selectedArea = responseData['data']['_id'];
//           areas.add(responseData['data']);
//         });
//         scaffoldMessengerKey.currentState?.showSnackBar(
//           SnackBar(content: Text('Area added successfully!')),
//         );
//       }
//     } else {
//       if (mounted) {
//         scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(content: Text('Failed to add area: ${response.body}')),
//       );
//       }
//     }
//   } catch (e) {
//     if (mounted) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(content: Text('Error adding area: $e')),
//     );
//     }
//   } finally {
//     if (mounted) {
//       _newAreaNameController.clear();
//       _newAreaDescriptionController.clear();
//       _newAreaCrimeRateController.clear();
//     }
//   }
// }

  // Future<void> getAllAreas(BuildContext context) async {
  //   String? token = await TokenHelper.getToken();
  //   try {
  //     final response = await http.get(
  //       Uri.parse('https://patrollingappbackend.onrender.com/api/v1/crime-areas'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer ${token}'
  //       },
  //     );
  //     print(response);

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseData = json.decode(response.body);

  //       setState(() {
  //         areas = responseData['data'];
  //         });

  //     }
  //   } catch (e) {
  //     // Handle any errors that occur during the request
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('An error occurred. Please try again. $e')),
  //     );
  //   }
  // }

  Future<void> assignWork(BuildContext context) async {
    _updateOfficerIds();
    print(selectedLocations);

    if (officers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one officer')),
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
              '${dotenv.env["BACKEND_URI"]}/assignments'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${token}'
          },
          body: json.encode({
            'officerIds': officerIds,
            'startsAt':
                DateTime.parse(_startTimeController.text).toUtc().toString(),
            'endsAt':
                DateTime.parse(_endTimeController.text).toUtc().toString(),
            'location': selectedLocations,
            'duration': '0',
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
          selectedLocations = [];
          _durationController.clear();
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

  Future<void> _selectDateTime(
      BuildContext context, TextEditingController controller) async {
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

  String calculateTimeDifference(String startTime, String endTime) {
    final format = DateFormat("HH:mm:ss");

    final start = format.parse(startTime);
    final end = format.parse(endTime);

    Duration diff;

    if (end.isAfter(start)) {
      diff = end.difference(start);
    } else {
      // If end time is "next day" (e.g., 23:00:00 to 01:00:00)
      diff = end.add(Duration(days: 1)).difference(start);
    }

    // Format back to HH:mm:ss
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hh = twoDigits(diff.inHours);
    String mm = twoDigits(diff.inMinutes.remainder(60));
    String ss = twoDigits(diff.inSeconds.remainder(60));

    return "$hh:$mm:$ss";
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    // _newAreaNameController.dispose();
    // _newAreaDescriptionController.dispose();
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
        backgroundColor: Colors.blue[800],
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
                    _buildAreaTextField(context),
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
                  officers.isEmpty
                      ? "No officers selected"
                      : "${officers.length} officers selected",
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
              icon: Icon(Icons.add, color: Colors.white, size: 20),
              label: Text(
                "Add",
                style: TextStyle(color: Colors.white),
              ),
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

  Widget _buildAreaTextField(BuildContext context) {
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
        SizedBox(height: 12),
        ElevatedButton.icon(
          icon: Icon(Icons.location_pin),
          label: Text("Select Area"),
          onPressed: () async {
            final selected = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => MapPointSelector()));
            if (selected != null) {
              setState(() {
                selectedLocations = selected!;
                // _longitudeController.text = selected.longitude.toString();
                // _latitudeController.text = selected.latitude.toString();
              });
            }
          },
        ),
        if (selectedLocations.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedLocations.map((loc) {
              return Chip(
                label: Text(
                  "${loc.latitude} , ${loc.longitude}",
                  style: TextStyle(color: Colors.white),
                ),
                deleteIcon: Icon(Icons.close, size: 18, color: Colors.white),
                onDeleted: () => _removeLocation(
                    loc.latitude.toString(), loc.longitude.toString()),
                backgroundColor: Colors.blue.shade600,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
