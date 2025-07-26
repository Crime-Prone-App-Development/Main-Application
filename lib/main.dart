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
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mainapp/services/firebase_notification_service.dart';
import './services/alarm_Service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await AlarmService.executeTask(inputData ?? {});
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('notifications');
  await dotenv.load(fileName: ".env");

  FirebaseNotificationService.initializeFCM();
  await NotificationService().initialize();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await AlarmService.initialize();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
    ],
    child: AppLoader(),
  ));
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

Future<bool> isValidToken(token) async {
  try {
    final response = await http.get(
        Uri.parse('${dotenv.env["BACKEND_URI"]}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      // final Map<String, dynamic> responseData = json.decode(response.body);
      return true;
    } else {
      return false;
    }
  } catch (e) {
    // Handle any errors that occur during the request
    print("error verifying user: ${e}");
    return false;
  }
}

class AppLoader extends StatefulWidget {
  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<List<String?>>(
        future: TokenHelper.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
            return Scaffold(
              body: Center(
                child: Text("Error: \${snapshot.error}"),
              ),
            );
          } else {
            final List<String?>? userInfo = snapshot.data;
            final String? token = userInfo!.isNotEmpty ? userInfo[0] : null;
            final String? role = userInfo.length > 4 ? userInfo[4] : null;

            if (token == null) {
              return MyApp(initialRoute: '/role');
            }

            return FutureBuilder<bool>(
              future: isValidToken(token),
              builder: (context, tokenSnapshot) {
                if (tokenSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/logos/up_police_logo.jpeg'),
                        radius: 60,
                      ),
                    ),
                  );
                } else {
                  final bool isValid = tokenSnapshot.data ?? false;
                  return MyApp(
                    initialRoute: isValid
                        ? (role != 'ADMIN' ? '/home' : '/adminHome')
                        : '/role',
                  );
                }
              },
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
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
