import 'dart:io';
// import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';
// import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mainapp/police_side/appbar.dart';
import 'package:mainapp/police_side/checkpoint.dart';
import 'package:mainapp/police_side/history.dart';
import 'package:mainapp/police_side/incident.dart';
import 'package:mainapp/police_side/profile.dart';
import 'package:mainapp/police_side/report.dart';
import 'package:mainapp/police_side/scan.dart';
import 'package:mainapp/police_side/uploadImage.dart';
import 'package:mainapp/token_helper.dart';
import 'assignmentPage.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

import '../userProvider.dart';
// import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

enum AlertType { panic, alert }

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  Position? currentLocation;
  StreamSubscription? subscription;
  int _selectedIndex = 0;
  bool incident = false;
  bool uploadImage = false;
  bool checkpoint = false;

  late List userData = [];

  String? alertDescription;
  AlertType? selectedAlertType;

  IO.Socket? socket;

  locationPermission({VoidCallback? inSuccess}) async {
    /// this function is responsible for asking permission and checking whether user have granted or
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.openAppSettings();
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return Future.error('Location permissions are permanently denied');
    }
    ;
    {
      inSuccess?.call();
    }
  }

  void startListeningLocation() {
    locationPermission(
      inSuccess: () async {
        subscription = Geolocator.getPositionStream(
                locationSettings: Platform.isAndroid
                    ? AndroidSettings(
                        foregroundNotificationConfig:
                            const ForegroundNotificationConfig(
                                notificationTitle:
                                    'location fetching in background',
                                notificationText:
                                    "current location is fetched in background",
                                enableWakeLock: true))
                    : AppleSettings(
                        accuracy: LocationAccuracy.high,
                        activityType: ActivityType.fitness,
                        pauseLocationUpdatesAutomatically: true,
                        showBackgroundLocationIndicator: false,
                      ))
            .listen((event) async {
          setState(() {
            currentLocation = event;
            // print(currentLocation);
          });
        });
      },
    );
  }

  Future<void> _connectToSocket() async {
    String? token = await TokenHelper.getToken();
    // Establish socket connection
    socket = IO.io(
        'https://patrollingappbackend.onrender.com',
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            // .disableAutoConnect()  // disable auto-connection
            .setExtraHeaders({'authorization': "$token"}) // optional
            .build());

    socket?.onConnect((_) {
      print('Connected to Socket Server');
    });

    socket?.on("selfie_prompt", (msg) {
      print(msg);
    });

    socket?.onDisconnect((_) {
      print('Disconnected from server');
    });

    socket?.on('locatioLogged', (msg) {
      print(msg);
    });

    Timer.periodic(Duration(seconds: 10), (timer) async {
      startListeningLocation();
      // Send location data to the server using Socket.IO
      socket?.emit('locationUpdate', {
        'latitude': currentLocation?.latitude,
        'longitude': currentLocation?.longitude,
      });

      // print(
      //     'Background Location: ${currentLocation?.latitude}, ${currentLocation?.longitude}');
    });
  }

  Future<void> _emitEvent(
      String event, Map<String, dynamic> data, String roomId) async {
    if (socket == null || !socket!.connected) {
      await _connectToSocket();
    }

    socket?.emit(event, {...data, 'room': roomId});
  }

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUser();
    });
    startListeningLocation();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    List data = await TokenHelper.getUserData();
    setState(() {
      userData = data; // Update the state with the fetched data
    });
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Send Emergency Alert'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<AlertType>(
                    value: selectedAlertType,
                    hint: Text('Select alert type'),
                    items: [
                      DropdownMenuItem(
                        value: AlertType.panic,
                        child: Text('Panic - Immediate Assistance'),
                      ),
                      DropdownMenuItem(
                        value: AlertType.alert,
                        child: Text('Alert - Report Incident'),
                      ),
                    ],
                    onChanged: (AlertType? value) {
                      setState(() {
                        selectedAlertType = value;
                        if (value == AlertType.panic) {
                          alertDescription =
                              'PANIC ALERT - IMMEDIATE ASSISTANCE NEEDED';
                        }
                      });
                    },
                  ),
                  if (selectedAlertType == AlertType.alert)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          alertDescription = value;
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Send'),
                  onPressed: () async {
                    if (selectedAlertType == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select an alert type')),
                      );
                      return;
                    }

                    if (selectedAlertType == AlertType.alert &&
                        (alertDescription == null ||
                            alertDescription!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a description')),
                      );
                      return;
                    }

                    _sendAlertToServer();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
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

  void _sendAlertToServer() async {
    // Get current location (you'll need the geolocator package)
    // Position position = await Geolocator.getCurrentPosition();
    // String location = '${position.latitude},${position.longitude}';

    // For now, using a placeholder location
    Position location = await _getCurrentLocation();

    // Emit the alert to the server
    await _emitEvent(
        'emergency-alert',
        {
          'type': selectedAlertType == AlertType.panic ? 'panic' : 'alert',
          'userId': userData[1],
          'userName': userData[2],
          'location': location,
          'description': alertDescription,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'admin');

    // Show confirmation to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Emergency alert sent! Help is on the way!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xffbbdeff),
        selectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            incident = false;
            uploadImage = false;
            checkpoint = false;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                size: 30,
              ),
              label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: 30,
              ),
              label: "Profile"),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.history,
                size: 30,
              ),
              label: "History"),
        ],
      ),
      body: Column(
        children: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              if (userProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userProvider.error != null) {
                return Center(child: Text(userProvider.error!));
              }

              if (userProvider.user == null) {
                return const Center(child: Text('No user data'));
              }
              // setState(() {
              //   userData = userProvider.user ?? [];
              // });
              return Appbar0(
                userData: userProvider.user ?? [],
              ); // Default return statement
            },
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: setcurrentPage(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget setcurrentPage(int index) {
    switch (index) {
      case 0:
        return incident
            ? uploadImage
                ? UploadImagesScreen(
                    uploadImage: uploadImage,
                    onUpdateUploadImage: (bool) {
                      setState(() {
                        uploadImage = false;
                      });
                    },
                  )
                : incidentReport(
                    incident: incident,
                    onUpdateIncident: (_) {
                      setState(() {
                        incident = false;
                      });
                      // ignore: avoid_types_as_parameter_names
                    },
                    onUpdateUploadImage: (bool) {
                      setState(() {
                        uploadImage = true;
                      });
                    },
                    uploadImage: uploadImage,
                  )
            : checkpoint
                ? CheckpointsPage()
                : home();
      case 1:
        return ProfilePage();
      case 2:
        return HistoryPage();

      default:
        return home();
    }
  }

  Widget home() {
    return Column(
      children: [
        _buildShiftCard(),
        // _buildCheckpointStatus(),
        _buttons(),
        SizedBox(height: 20),
        // _buildGoogleMap(),
      ],
    );
  }

  Widget _buildAppBar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Color(0xffbbdeff),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/logos/up_police_logo.jpeg'),
                    radius: 30,
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.notifications,
                  size: 45,
                  color: Colors.black,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Container(
          height: 80,
          width: double.infinity,
          color: Color(0xff1b0573),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8),
            child: Container(
              color: Colors.white,
              height: 40,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: userData.isEmpty
                        ? [Text("N/A"), Text("N/A")]
                        : [Text(userData[2]), Text(userData[3])]),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildShiftCard() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.assignment, color: Colors.black),
                title: Text(
                  "Assignments",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AssignmentPage()),
                      );
                    },
                    icon: Icon(Icons.arrow_forward_ios)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckpointStatus() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.location_on, color: Colors.black),
                title: Text(
                  "Total Checkpoints (2)",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                // In your ListTile's trailing button:
                trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CheckpointsPage()),
                      );
                    },
                    icon: Icon(Icons.arrow_forward_ios)),
                // trailing: IconButton(
                //     onPressed: () {
                //       setState(() {
                //         checkpoint = true;
                //       });
                //     },
                //     icon: Icon(Icons.arrow_forward_ios)),
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  "Completed Checkpoints (2/2)",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.red),
                title: Text(
                  "Missed Checkpoints (0/2)",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                // Reset previous selections
                selectedAlertType = null;
                alertDescription = null;
                _showAlertDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(170, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Alert Button",
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    incident = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff4FA9FC),
                  minimumSize: Size(170, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Incident Report",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ))
          ],
        ),
        // SizedBox(height: 10),
        // ElevatedButton(
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (context) => DailyReportPage()),
        //       );
        //     },
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Color.fromARGB(255, 16, 213, 85),
        //       minimumSize: Size(370, 45),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(10),
        //       ),
        //     ),
        //     child: Text(
        //       "Incident Report",
        //       style: TextStyle(fontSize: 20, color: Colors.black),
        //     ))
      ],
    );
  }
}

// class PerfectHeightCard extends StatelessWidget {
//   final String title;
//   final String areaName;
//   final TimeOfDay startsAt;
//   final TimeOfDay endsAt;

//   const PerfectHeightCard({
//     super.key,
//     required this.title,
//     required this.areaName,
//     required this.startsAt,
//     required this.endsAt,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Card(
//         elevation: 2,
//         margin: EdgeInsets.zero, // Remove card's default margin
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(
//             minWidth: double.infinity, // Full width
//             maxWidth: double.infinity,
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: IntrinsicHeight(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min, // Crucial for height
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Title and Time
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           title,
//                           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.w600,
//                             color: Colors.blue[800],
//                           ),
//                         ),
//                       ),
//                       _buildTimeBadge(context),
//                     ],
//                   ),
//                   const SizedBox(height: 12),

//                   // Location
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           areaName,
//                           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTimeBadge(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: Colors.blue[50],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         '${_formatTime(startsAt)} - ${_formatTime(endsAt)}',
//         style: Theme.of(context).textTheme.labelMedium?.copyWith(
//           fontWeight: FontWeight.w600,
//           color: Colors.blue[800],
//         ),
//       ),
//     );
//   }

//   String _formatTime(TimeOfDay time) {
//     final hour = time.hourOfPeriod;
//     final minute = time.minute.toString().padLeft(2, '0');
//     final period = time.period == DayPeriod.am ? 'AM' : 'PM';
//     return '$hour:$minute $period';
//   }
// }
