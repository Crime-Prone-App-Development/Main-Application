import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mainapp/resetpass.dart';
import 'package:pinput/pinput.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class OTPPage extends StatefulWidget {
  final String badgeNumber;
  final String phoneNumber;

  const OTPPage(
      {super.key, required this.badgeNumber, required this.phoneNumber});
  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  String finalPin = "";
  bool _isLoading = false;

  Future<Map<String, dynamic>?> verifyOTP(String otp) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env["BACKEND_URI"]}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"otp": otp, "badgeNumber": widget.badgeNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print(responseData);
        return responseData["data"];
      } else {
        print("OTP verification failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error verifying OTP: $e");
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                "OTP Verification",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Enter the verification code we just sent on your phone number ${widget.phoneNumber.substring(0, 3)}xxxx${widget.phoneNumber.substring(7, 10)}",
              ),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Pinput(
                    length: 6,
                    keyboardType: TextInputType.number,
                    defaultPinTheme: PinTheme(
                      margin: EdgeInsets.all(10),
                      width: 32,
                      height: 32,
                      textStyle:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xffC7E4FF),
                      ),
                    ),
                    onCompleted: (pin) {
                      setState(() {
                        finalPin = pin;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 30),
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
                    : () async {
                        if (finalPin.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("Please enter a valid 6-digit OTP")),
                          );
                          return;
                        }

                        final result = await verifyOTP(finalPin);

                        if (result != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResetPassword(responseData: result)
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("OTP verification failed")),
                          );
                        }
                      },
                child: Text("VERIFY",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ),
              SizedBox(height: 120),
              Center(
                child: InkWell(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
