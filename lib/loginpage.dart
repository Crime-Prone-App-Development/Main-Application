// import 'dart:ffi' hide Size;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mainapp/forgotpass.dart';
import 'dart:convert';
import './token_helper.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController phoneController = TextEditingController();

  TextEditingController passwordController = TextEditingController();

  bool homePageLoading = false;

  Future<void> _login(BuildContext context) async {
    final String phone = phoneController.text;
    final String password = passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final Map<String, String> requestBody = {
        'phoneNumber': phone,
        'password': password,
      };

      try {
        final response = await http.post(
          Uri.parse(
              'https://patrollingappbackend.onrender.com/api/v1/auth/login'),
          body: json.encode(requestBody),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          // If the server returns a 200 OK response, parse the JSON
          final Map<String, dynamic> responseData = json.decode(response.body);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Login Successful')));
          // print(jsonDecode(response.body));

          String? token = responseData['data']['Token'];
          String? userId = responseData['data']['user']['_id'];
          String? username = responseData['data']['user']['name'];
          String? userPhone = responseData['data']['user']['phoneNumber'];
          String? userRole = responseData['data']['user']['role'];

          if (token != null &&
              userId != null &&
              username != null &&
              userPhone != null &&
              userRole != null) {
            setState(() {
              homePageLoading = true;
            });
            await TokenHelper.saveToken(
                token: token,
                userId: userId,
                userName: username,
                userPhone: userPhone,
                userRole: userRole);

            setState(() {
              homePageLoading = false;
            });
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Login Failed ')));
            return;
          }

          homePageLoading
              ? CircularProgressIndicator()
              : Navigator.pushReplacementNamed(
                  context, userRole == 'ADMIN' ? '/adminHome' : '/home');
        } else {
          // If the server did not return a 200 OK response,
          // show an error message.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to login. Please try again.')),
          );
        }
      } catch (e) {
        // Handle any errors that occur during the request
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again. $e')),
        );
      }
    }
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
              children: <Widget>[
                SizedBox(height: 40),
                Image.asset('assets/logos/up_police_logo.jpeg',
                    height: 300), // Replace with correct path
                SizedBox(height: 40),
                Text(
                  "Login to get started!",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
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
                SizedBox(height: 20),
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
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff1B0573),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => {
                    _login(context),
                  },
                  child: Text("LOGIN",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => forgotPassword())),
                      },
                      child: Text("Forgot Password?",
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(width: 10),
                    InkWell(
                      onTap: () => {
                        Navigator.pushNamed(context, '/'),
                      },
                      child: Text("Back to Role Login Page",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                SizedBox(height: 60),
                InkWell(
                  onTap: () => {
                    Navigator.pushNamed(context, '/register'),
                  },
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: "Don't have an account? "),
                    TextSpan(
                        text: "Register Now",
                        style: TextStyle(color: Colors.red, fontSize: 16)),
                  ])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
