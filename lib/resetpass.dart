import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mainapp/loginpage.dart';
import 'package:http/http.dart' as http;
import './police_side/home.dart';
import './admin_side/home.dart';
import 'token_helper.dart';

class ResetPassword extends StatefulWidget {
  final bool requireOldPassword;
  final Map<String, dynamic> responseData;

  const ResetPassword(
      {super.key,
      this.requireOldPassword = false,
      this.responseData = const {}});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _passwordRegex =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$');

  Future<void> _resetPassword() async {
    final String otpStatus = widget.responseData["otpStatus"];
    final String userId = widget.responseData["user"][0]["_id"];
    final String password = passwordController.text;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env["BACKEND_URI"]}/auth/change-password-with-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "otpStatus": otpStatus,
          "userId": userId,
          "newPassword": password
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Password not Changed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetWithOldPass() async {
    final String oldPass = oldPasswordController.text;
    final String newPass = passwordController.text;

    final String? token = await TokenHelper.getToken();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env["BACKEND_URI"]}/users/change-password'),
        headers: {'Content-Type': 'application/json', "authorization": token!},
        body: jsonEncode({"oldPassword": oldPass, "newPassword": newPass}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Password not Changed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() async {
    String role = "";
    if (widget.requireOldPassword) {
      role = await TokenHelper.getRole() ?? "";
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Determine the target page based on the flag

        // final targetPage = widget.requireOldPassword
        //     ? role != "" && role == "ADMIN"
        //         ? adminHome()
        //         : homePage()
        //     : LoginPage();

        final targetPage = widget.requireOldPassword
            ? role != "" && role == "ADMIN"
                ? adminHome()
                : homePage()
            : LoginPage();

        Future.delayed(Duration(seconds: 2), () {

          Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => targetPage // Replace with desired page
));
// Navigator.pushAndRemoveUntil(
//     context,
//     MaterialPageRoute(builder: (context) => targetPage), // Your target page
//     (route) => false, // Remove all previous routes
//   );
        //   Navigator.pushNamedAndRemoveUntil(
        //     context,
        //     targetPage,
        //     (route) => false,
        //   );
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 20),
                Text(
                  "Password Changed!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  "Your Password has been changed successfully!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff1B0573),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => targetPage // Replace with desired page
));
                    
                  },
                  child: Text(
                    widget.requireOldPassword ? "Go to Home" : "Back to Login",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Redirecting in 5 seconds...",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (!_passwordRegex.hasMatch(value)) {
      return 'Password must be at least 8 characters with\nat least one letter, one number and one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your old password';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
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
                  "Reset Password",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),

                // Conditionally show old password field
                if (widget.requireOldPassword)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Enter Old Password",
                          filled: true,
                          fillColor: Colors.blue[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: _validateOldPassword,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Enter New Password",
                    filled: true,
                    fillColor: Colors.blue[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: _validatePassword,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Confirm New Password",
                    filled: true,
                    fillColor: Colors.blue[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff1B0573),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : widget.requireOldPassword
                          ? _resetWithOldPass
                          : _resetPassword,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("SUBMIT",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
