import 'package:flutter/material.dart';
import 'package:mainapp/admin_side/home.dart';
import 'package:mainapp/loginpage.dart';
import 'package:mainapp/otp_verify.dart';
import 'package:mainapp/police_side/home.dart';
import 'package:mainapp/police_side/incident.dart';
import 'package:mainapp/register.dart';
import 'package:mainapp/role.dart';
import './token_helper.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'admin_side/home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppLoader());
  await dotenv.load(fileName: ".env"); // Show a loader while checking the token
}

Future<void> _connectToSocket() async {
  String? token = await TokenHelper.getToken();
  // Establish socket connection
  IO.Socket socket = IO.io(
      'https://patrollingappbackend.onrender.com',
      IO.OptionBuilder().setTransports(['websocket']) // for Flutter or Dart VM
          // .disableAutoConnect()  // disable auto-connection
          .setExtraHeaders({'authorization': "$token"}) // optional
          .build());
  socket.onConnect((_) {
    print('Connected to Socket Server');
  });

  socket.on("selfie_prompt", (msg) {
    print(msg);
  });

  socket.onDisconnect((_) {
    print('Disconnected from server');
  });

  socket.on('locatioLogged', (msg) {
    print(msg);
  });

  Timer.periodic(Duration(seconds: 4), (timer) async {
    Position position = await _getCurrentLocation();
    // Send location data to the server using Socket.IO
    socket.emit('locationUpdate', {
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
    print('Background Location: ${position.latitude}, ${position.longitude}');
  });
}

Future<Position> _getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw 'Location services are disabled';
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw 'Location permissions are denied';
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw 'Location permissions are permanently denied';
  }

  return await Geolocator.getCurrentPosition();
}

class AppLoader extends StatefulWidget {
  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  @override
  void initState() {
    super.initState();
    _connectToSocket(); // moved here
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<List<String?>>(
        future: TokenHelper.getUserData(), // Check for token
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loader while waiting for the token check
            return Scaffold(
              body: Center(
                child: CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/logos/up_police_logo.jpeg'),
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
            final List<String?>? userInfo = snapshot.data;
            final String? token = userInfo!.isNotEmpty ? userInfo[0] : null;
            final String? role = userInfo.length > 4 ? userInfo[4] : null;

            return MyApp(
              initialRoute: token != null
                  ? (role != 'ADMIN' ? '/home' : '/adminHome')
                  : '/role',
            );
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
      title: 'Smart Police',
      initialRoute: initialRoute,
      routes: {
        '/role': (context) => roleChange(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => homePage(),
        '/adminHome': (context) => adminHome(),
        // '/incident': (context) => incidentReport(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
