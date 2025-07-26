import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController badgeIdController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  String role = 'GENERAL';
  final List<String> items = ['GENERAL', 'ADMIN']; // Define dropdown items

  // Function to send registration data to the backend
  Future<void> _registerUser(BuildContext context) async {
    // Capture input data
    final String name = nameController.text;
    final String phone = phoneController.text;
    final String badgeId = badgeIdController.text;
    final String password = passwordController.text;

    // Validate input fields
    if (name.isEmpty || phone.isEmpty || badgeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final Map<String, String> requestBody = {
      'name': name,
      'badgeNumber': badgeId,
      'phoneNumber': phone,
      'password': password,
      'role': "GENERAL",
    };

    try {
      // Send a POST request to the backend
      final response = await http.post(
        Uri.parse('${dotenv.env["BACKEND_URI"]}/auth/register'),
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                backgroundColor: Colors.black,
                radius: 22,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              SizedBox(height: 50),
              Text(
                "Register yourself",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Enter Name",
                  filled: true,
                  fillColor: Colors.blue[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: "Enter Phone Number",
                  filled: true,
                  fillColor: Colors.blue[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: badgeIdController,
                decoration: InputDecoration(
                  hintText: "Enter Badge ID",
                  filled: true,
                  fillColor: Colors.blue[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Enter Password",
                  filled: true,
                  fillColor: Colors.blue[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              // SizedBox(
              //   height: 15,
              // ),
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.blue[100], // Background color
              //     borderRadius: BorderRadius.circular(10)), // Rounded corners
              //     child: Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 12.0),
              //       child: DropdownButton<String>(
              //         value: role, // Current selected value
              //         hint: Text(
              //           'Select Role',
              //           style: TextStyle(
              //               color: Colors.grey[600]), // Hint text color
              //         ), // Hint text when no value is selected
              //         onChanged: (String? newValue) {
              //           setState(() {
              //             if (newValue != null) {
              //               role = newValue;
              //             }// Update the selected value
              //           });
              //         },
              //         items:
              //             items.map<DropdownMenuItem<String>>((String value) {
              //           return DropdownMenuItem<String>(
              //             value: value,
              //             child: Text(value),
              //           );
              //         }).toList(),
              //         isExpanded: true, // Expands to fill the width
              //         underline: Container(), // Remove the default underline
              //         icon: Icon(Icons.arrow_drop_down,
              //             color: Colors.grey[700]), // Custom dropdown icon
              //       ),
              //     ),
              //   ),
              SizedBox(height: 120),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff1B0573),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _registerUser(context),
                child: Text("REGISTER",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
