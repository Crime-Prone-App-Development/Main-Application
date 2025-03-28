import 'package:flutter/material.dart';
import 'package:mainapp/admin_side/home.dart';
import 'package:mainapp/loginpage.dart';
import 'package:mainapp/otp_verify.dart';
import 'package:mainapp/police_side/home.dart';
import 'package:mainapp/police_side/incident.dart';
import 'package:mainapp/register.dart';
import './token_helper.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'admin_side/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _connectToSocket(); 
  runApp(AppLoader()); // Show a loader while checking the token
}
Future<void> _connectToSocket() async{
  String? token = await TokenHelper.getToken();
  // Establish socket connection
  IO.Socket socket = IO.io('https://patrollingappbackend.onrender.com', IO.OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Dart VM
      // .disableAutoConnect()  // disable auto-connection
      .setExtraHeaders({'authorization': "$token"})// optional
      .build());
  socket.onConnect((_) {
    print('Connected to Socket Server');
  });

  socket.on("selfie_prompt", (msg){
      print(msg);
    });

  socket.onDisconnect((_) {
      print('Disconnected from server');
  });

  socket.on('locatioLogged', (msg) {

    print(msg);
  });
  
  Timer.periodic(Duration(seconds : 4), (timer) async {
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

class AppLoader extends StatelessWidget {
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
            final List<String?>? userInfo = snapshot.data;
            return MyApp(initialRoute: userInfo![0] != null ? userInfo[4] != 'ADMIN' ? '/home' : '/adminHome' : '/login');
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
        '/adminHome' : (context) => adminHome(),
        // '/incident': (context) => incidentReport(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
