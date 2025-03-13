import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OTPPage extends StatefulWidget {
  final String phoneNumber;

  const OTPPage({super.key, required this.phoneNumber});
  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
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
                "Enter the verification code we just sent on your phone number +91 ${widget.phoneNumber}",
              ),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Pinput(
                    length: 4,
                    keyboardType: TextInputType.number,
                    defaultPinTheme: PinTheme(
                      margin: EdgeInsets.all(10),
                      width: 56,
                      height: 56,
                      textStyle:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xffC7E4FF),
                      ),
                    ),
                    onCompleted: (pin) {
                      print("Entered OTP: $pin");
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
                onPressed: () {},
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
