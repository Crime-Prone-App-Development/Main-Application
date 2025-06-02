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
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import './userProvider.dart';
import './notifications_service.dart';
import 'reportsProvider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await initializeService();
  await NotificationService().initialize();
  runApp(MultiProvider(
    providers : [
      ChangeNotifierProvider(create : (_) => UserProvider()),
      // ChangeNotifierProvider(create: (_) => ReportsProvider()),
      // ChangeNotifierProxyProvider<UserProvider, AssignmentProvider>(
      //   create: (context) => AssignmentProvider(),
      //   update: (context, userProvider, assignmentProvider) {
      //     assignmentProvider?.updateUserProvider(userProvider);
      //     return assignmentProvider ?? AssignmentProvider();
      //   },
      // ),
    ],
    child : AppLoader()
  ));
  await dotenv.load(fileName: ".env"); // Show a loader while checking the token
}


void startBackgroundService() {
  final service = FlutterBackgroundService();
  service.startService();
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   await service.configure(
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//     androidConfiguration: AndroidConfiguration(
//       autoStart: true,
//       onStart: onStart,
//       isForegroundMode: false,
//       autoStartOnBoot: true,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();

//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   final socket = IO.io("your-server-url", <String, dynamic>{
//     'transports': ['websocket'],
//     'autoConnect': true,
//   });
//   socket.onConnect((_) {
//     print('Connected. Socket ID: ${socket.id}');
//     // Implement your socket logic here
//     // For example, you can listen for events or send data
//   });

//   socket.onDisconnect((_) {
//     print('Disconnected');
//   });
//    socket.on("event-name", (data) {
//     //do something here like pushing a notification
//   });
//   service.on("stop").listen((event) {
//     service.stopSelf();
//     print("background process is now stopped");
//   });

//   service.on("start").listen((event) {});

//   Timer.periodic(const Duration(seconds: 1), (timer) {
//     socket.emit("event-name", "your-message");
//     print("service is successfully running ${DateTime.now().second}");
//   });
// }

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
  // _connectToSocket(); // moved here
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
