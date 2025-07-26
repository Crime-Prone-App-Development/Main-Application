import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mainapp/loginpage.dart';
import 'package:mainapp/token_helper.dart';

import 'package:provider/provider.dart';
import 'package:mainapp/userProvider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mainapp/resetpass.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<dynamic> userInfo = [];
  File? _pickedImage;
  late TextEditingController _dobController;
  late TextEditingController _hireDateController;
  bool _isEditing = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    setState(() {
      userInfo = context.read<UserProvider>().user!;
    });

    _dobController = TextEditingController(text: '');
    _hireDateController = TextEditingController(text: '');
    _initPrefs();
  }
  void printRouteStack(BuildContext context) {
  Navigator.of(context).widget.pages.forEach((page) {
    print('Route: ${page.name ?? page.runtimeType}');
  });
}

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    // Load saved values if they exist
    setState(() {
      _dobController.text = _prefs.getString('user_dob') ?? '';
      _hireDateController.text = _prefs.getString('user_hire_date') ?? '';
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Basic Information'),
              IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                onPressed: _toggleEditing,
                tooltip: _isEditing ? 'Save changes' : 'Edit profile',
              ),
            ],
          ),
          _buildEditableInfoItem('Date of Birth', _dobController,
              isEditing: _isEditing),
          _buildEditableInfoItem('Hire Date', _hireDateController,
              isEditing: _isEditing),
          _buildInfoItem('Shift Schedule', 'Not Scheduled'),
          _buildInfoItem('Assigned Location', 'N/A'),
          SizedBox(height: 24),
          _buildSectionTitle('Performance Metrics'),
          GridView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            children: [
              _buildMetricCard('Total Patrols Completed', '0'),
              _buildMetricCard('Incidents Reported', '0'),
              _buildMetricCard('Response Time Average', '0 mins'),
              _buildMetricCard('Satisfaction Rating', '☆☆☆☆☆ (0%)'),
            ],
          ),
          SizedBox(height: 24),
          _buildSectionTitle('Recent Activity'),
          _buildInfoItem('Last Patrol Date', 'N/A'),
          _buildInfoItem('Total Checkpoints Visited', '0'),
          _buildInfoItem('Incidents Reported', '0'),
          _buildInfoItem('Notes', ''),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userInfo[2],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Badge ID: ${userInfo[5]}'),
                      Text('Contact: ${userInfo[3]}'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                  icon: Icon(Icons.security, size: 18),
                  label: Text('Change Password', style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    iconColor: Colors.white
                  ),
                  onPressed: () async => {
                    printRouteStack(context),
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ResetPassword(
                                      requireOldPassword: true,
                                    )))
                      }),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: Icon(Icons.logout, size: 18),
                label: Text('Logout', style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  iconColor: Colors.white
                ),
                onPressed: _handleLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Logout', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Clear all stored data
      await TokenHelper.clearData();

      // Navigate to login screen and clear all routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LoginPage()), // Replace with your login screen
        (route) => false,
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Card(
      margin: EdgeInsets.all(1),
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save logic would go here
        _saveChanges();
      }
    });
  }

  Future<void> _saveChanges() async {
    try {
      // Save to SharedPreferences
      await _prefs.setString('user_dob', _dobController.text);
      await _prefs.setString('user_hire_date', _hireDateController.text);

      // Update the user provider if needed
      // context.read<UserProvider>().updateUserInfo({
      //   'dob': _dobController.text,
      //   'hireDate': _hireDateController.text,
      // });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
      );
    }
  }

  Widget _buildEditableInfoItem(String label, TextEditingController controller,
      {required bool isEditing}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: isEditing
                ? TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, controller),
                      ),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onTap: () => _selectDate(context, controller),
                    readOnly: true,
                  )
                : Text(
                    controller.text.isEmpty ? 'N/A' : controller.text,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
