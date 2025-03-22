import 'package:flutter/material.dart';
import 'package:mainapp/loginpage.dart';
import 'package:mainapp/otp_verify.dart';
import 'package:mainapp/police_side/home.dart';
import 'package:mainapp/police_side/incident.dart';
import 'package:mainapp/register.dart';
import './token_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  runApp(AppLoader()); // Show a loader while checking the token
}

class AppLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<String?>(
        future: TokenHelper.getToken(), // Check for token
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loader while waiting for the token check
            return Scaffold(
              body: Center(
                child: CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/logos/up_police_logo.png'),
                    radius: 60,
                  ),
              ),
            );
          } else if (snapshot.hasError) {
            // Handle errors
            return Scaffold(
              body: Center(
                child: Text("Error: ${snapshot.error}"),
              ),
            );
          } else {
      
            final String? token = snapshot.data;
            return MyApp(initialRoute: token != null ? '/home' : '/login');
          }
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {

  final String initialRoute;
  MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginPage(),
        // '/otp': (context) => OTPPage(
        //       phoneNumber: ModalRoute.of(context)?.settings.arguments as String,
        //     ),
        '/register': (context) => RegisterPage(),
        '/home': (context) => homePage(),
        // '/incident': (context) => incidentReport(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
