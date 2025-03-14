import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class scanCheckpoint extends StatefulWidget {
  final bool scan;
  final Function(bool) onUpdateScan;
  const scanCheckpoint(
      {super.key, required this.scan, required this.onUpdateScan});

  @override
  State<scanCheckpoint> createState() => _scanCheckpointState();
}

class _scanCheckpointState extends State<scanCheckpoint> {
  XFile? _image;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          Container(
            height: 400,
            decoration: BoxDecoration(border: Border.all(width: 1)),
            child: _image == null
                ? Center(
                    child: Text(
                      "No image selected",
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : Image.file(
                    File(_image!.path),
                    fit: BoxFit.cover,
                  ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _pickImage();
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 45),
                    backgroundColor: Color(0xff4FA9FC),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text(
                  "Take Photo",
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onUpdateScan(!widget.scan);
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 45),
                    backgroundColor: Color(0xff118E13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text(
                  "Upload Photo",
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
