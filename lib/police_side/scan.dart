import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mainapp/token_helper.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';

class ScanCheckpointPage extends StatefulWidget {
  final String assignmentId;
  const ScanCheckpointPage({Key? key, required this.assignmentId}) : super(key: key);

  @override
  State<ScanCheckpointPage> createState() => _ScanCheckpointPageState();
}

class _ScanCheckpointPageState extends State<ScanCheckpointPage> {

  
  XFile? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  bool _isSubmitting = false;
  String? _latitude;
  String? _longitude;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }
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
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _submitVerificationImage(BuildContext context, String assignmentId) async {

    setState(() {
      _isLoading = true;
    });

    String? token = await TokenHelper.getToken();

    setState(() => _isSubmitting = true);

    // Validation
    if (_image == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    var uri = Uri.parse('https://patrollingappbackend.onrender.com/api/v1/selfies/${assignmentId}');
    var request = http.MultipartRequest('POST', uri);

    // Headers - Remove Content-Type header!
    request.headers['authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';


    // Add files using fromPath for better memory management
    request.files.add(await http.MultipartFile.fromPath(
      'image',  // Changed from 'images' to 'image' for single file
      File(_image!.path).path,
      filename: basename(File(_image!.path).path),
    ));

    request.fields['imgLat'] = _latitude!;
    request.fields['imgLon'] = _longitude!;

    try {
      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted successfully')),
        );
        // Clear form after successful submission
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $respStr')),
        );
      }
      

      // 3. On success:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkpoint submitted successfully')),
        );
        Navigator.pop(context, true); // Return success status to previous page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Checkpoint'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            // Image Preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(width: 1)),
                child: _image == null
                    ? const Center(child: Text("No image selected"))
                    : Stack(
                        children: [
                          Image.file(File(_image!.path), fit: BoxFit.cover),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Take Photo Button
                ElevatedButton(
                  onPressed: () async{
                    await _pickImage();
                    await _getCurrentLocation(context);
                  },
                  style: _buttonStyle(Colors.blue),
                  child: const Text("Take Photo"),
                ),
                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitVerificationImage(context, widget.assignmentId),
                  style: _buttonStyle(Colors.green),
                  child: _isLoading
                      ? _loadingIndicator()
                      : const Text("Submit"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(150, 45),
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _loadingIndicator() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}