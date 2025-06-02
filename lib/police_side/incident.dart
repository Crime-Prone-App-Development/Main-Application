import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mainapp/police_side/home.dart';
import 'package:http/http.dart' as http;
import 'package:mainapp/token_helper.dart';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:geolocator/geolocator.dart';

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
  List<File> _selectedImages = []; // To store selected images
  final _descriptionController =
      TextEditingController(); // For incident description
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _isSubmitting = false;

  String type = 'Incident Report';
  final List<String> items = ["Incident Report", "Daily Report"]; 

  Future<void> _getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')),
      );
      return;
    }

    // If we reach here, permissions are granted and we can get the location
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _pickImages(BuildContext context) async {
  try {
    final ImagePicker picker = ImagePicker();
    
    // Show dialog to choose source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        
        title: Text("Select Image Source"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: Icon(Icons.camera_alt, size: 40,),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: Icon(Icons.image, size: 40,),
          ),
        ],
      ),
    );

    if (source == null) return; // User cancelled

    List<XFile> pickedFiles = [];
    
    if (source == ImageSource.gallery) {
      pickedFiles = await picker.pickMultiImage(
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
    } else {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (file != null) pickedFiles.add(file);
    }

    if (pickedFiles.isNotEmpty) {
      setState(() {
        int remainingSlots = 6 - _selectedImages.length;
        if (remainingSlots > 0) {
          int filesToAdd = pickedFiles.length > remainingSlots
              ? remainingSlots
              : pickedFiles.length;
          for (int i = 0; i < filesToAdd; i++) {
            _selectedImages.add(File(pickedFiles[i].path));
          }
        }
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
    print("Image picker error: $e");
  }
}

  Future<void> _submitReport(BuildContext context) async {
    final String latitude = _latitudeController.text;
    final String longitude = _longitudeController.text;
    final String description = _descriptionController.text;
    String? token = await TokenHelper.getToken();

    setState(() => _isSubmitting = true);

    // Validation
    if (_selectedImages.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    if (description.isEmpty || latitude.isEmpty || longitude.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    var uri = Uri.parse('https://patrollingappbackend.onrender.com/api/v1/report');
    var request = http.MultipartRequest('POST', uri);

    // Headers - Remove Content-Type header!
    request.headers['authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Add fields
    request.fields['description'] = description;
    request.fields['latitude'] = latitude;
    request.fields['longitude'] = longitude;
    request.fields['type'] = type;

    // Add files using fromPath for better memory management
    for (var image in _selectedImages) {
      request.files.add(await http.MultipartFile.fromPath(
        'images', // Must match server field name
        image.path,
        filename: basename(image.path),
      ));
    }

    try {
      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted successfully')),
        );
        // Clear form after successful submission
        _descriptionController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
        setState(() => _selectedImages.clear());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $respStr')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
                decoration: BoxDecoration(
                  color: Colors.blue[100], // Background color
                  borderRadius: BorderRadius.circular(10)), // Rounded corners
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: DropdownButton<String>(
                      value: type, // Current selected value
                      hint: Text(
                        'Select Role',
                        style: TextStyle(
                            color: Colors.grey[600]), // Hint text color
                      ), // Hint text when no value is selected
                      onChanged: (String? newValue) {
                        setState(() {
                          if (newValue != null) {
                            type = newValue;
                          }// Update the selected value
                        });
                      },
                      items:
                          items.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      isExpanded: true, // Expands to fill the width
                      underline: Container(), // Remove the default underline
                      icon: Icon(Icons.arrow_drop_down,
                          color: Colors.grey[700]), // Custom dropdown icon
                    ),
                  ),
                ),
                SizedBox(
                height: 15,
              ),
          Column(
            children: [
              if (_selectedImages.isNotEmpty) ...[
                Text('Selected: ${_selectedImages.length}/6 images'),
                SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),

          // File selection button
          ElevatedButton(
            onPressed: () => _pickImages(context),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 68),
              backgroundColor: Color(0xff118E13),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Upload Images (Max 6)",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          SizedBox(height: 20),

          // Coordinates input
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                      hintText: "Latitude",
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                Container(
                  height: 24.0,
                  width: 1.0,
                  color: Colors.grey,
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                ),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                      hintText: "Longitude",
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => {_getCurrentLocation(context)},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Use Current Location",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Description field
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.lightBlue[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "(Enter Description of Incident)",
                hintStyle: TextStyle(fontWeight: FontWeight.bold),
                border: InputBorder.none,
              ),
            ),
          ),

          SizedBox(height: 20),

          // Submit button
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitReport(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff118E13),
              minimumSize: Size(double.infinity, 68),
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Submit Report",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
