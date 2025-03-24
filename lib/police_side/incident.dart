import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mainapp/police_side/home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class incidentReport extends StatefulWidget {
  final bool incident;
  final bool uploadImage;
  final Function(bool) onUpdateIncident;
  final Function(bool) onUpdateUploadImage;

  const incidentReport(
      {super.key,
      required this.incident,
      required this.onUpdateIncident,
      required this.onUpdateUploadImage,
      required this.uploadImage});

  @override
  State<incidentReport> createState() => _incidentReportState();
}

class _incidentReportState extends State<incidentReport> {
  File? _image;
  final picker = ImagePicker();

  TextEditingController locationController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  Future<void> _submitReport(BuildContext context) async{
    final String location = locationController.text;
    final String description = descriptionController.text;

    // Validate input fields
    if (location.isEmpty ||description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final Map<String, String> requestBody = {
      // only send the picked images array here in images
      'images' : '', // array of File(Image.path)
      'location': location,
      'description': description,
    };

    try {
      // Send a POST request to the backend
      final response = await http.post(
        Uri.parse('http://192.168.173.155:8080/api/v1/report'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Handle the response
      if (response.statusCode == 202) {
        // Registration successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration successful!")),
        );
        Navigator.pop(context); // Navigate back to the previous screen
      } else {
        // Registration failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: ${response.body}")),
        );
      }
    } catch (e) {
      // Handle network or server errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 52,
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.lightBlue[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "(No file chosen)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              widget.onUpdateUploadImage(!widget.uploadImage);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 68),
              backgroundColor: Color(0xff118E13),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Upload Image",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.lightBlue[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "(No file chosen)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.lightBlue[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: locationController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "(Enter Location of Incident)",
                hintStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.lightBlue[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              // controller: _incidentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "(Enter Description of Incident)",
                hintStyle: TextStyle(fontWeight: FontWeight.bold),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onUpdateIncident(!widget.incident);
              _submitReport(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff118E13),
              minimumSize: Size(double.infinity, 68),
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Submit Report",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
