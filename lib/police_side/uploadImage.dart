import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadImagesScreen extends StatefulWidget {
  final bool uploadImage;
  final Function(bool) onUpdateUploadImage;
  const UploadImagesScreen({
    super.key,
    required this.uploadImage,
    required this.onUpdateUploadImage,
  });

  @override
  State<UploadImagesScreen> createState() => _UploadImagesScreenState();
}

class _UploadImagesScreenState extends State<UploadImagesScreen> {
  List<File> _imageFiles = [];

  Future<void> _pickImage() async {
    if (_imageFiles.length >= 6) {
      _showNoMoreSpaceAlert();
      return;
    }

    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(File(pickedFile.path));
      });
    }
  }

  void _showNoMoreSpaceAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Limit Reached"),
          content: const Text("You can only upload up to 6 images."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 450,
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              if (index < _imageFiles.length) {
                return Image.file(
                  _imageFiles[index],
                  fit: BoxFit.cover,
                );
              } else {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 10,
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: Icon(Icons.add_a_photo,
                        size: 50, color: Colors.black54),
                  ),
                );
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: () {
              widget.onUpdateUploadImage(!widget.uploadImage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff118E13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 60),
            ),
            child: const Text(
              "Upload Image",
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
