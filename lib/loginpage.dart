import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  TextEditingController phoneController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),

              Image.asset('assets/logos/up_police_logo.png',
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff1B0573),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/otp',
                      arguments: phoneController.text);
                },
                child: Text("LOGIN",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
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
    );
  }
}
