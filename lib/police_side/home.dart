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

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  int _selectedIndex = 0;
  bool incident = false;
  bool uploadImage = false;
  bool scan = false;
  bool checkpoint = false;

  late List userData = [];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    List data = await TokenHelper.getUserData();
    setState(() {
      userData = data; // Update the state with the fetched data
    });
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
            scan = false;
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
          Appbar0(),
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
            : scan
                ? scanCheckpoint(
                    scan: scan,
                    onUpdateScan: (bool) {
                      setState(() {
                        scan = false;
                      });
                    },
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
        _buildCheckpointStatus(),
        _buttons(),
        SizedBox(height: 20),
        // _buildGoogleMap(),
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
              onPressed: () {
                setState(() {
                  scan = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1D3D9B),
                minimumSize: Size(double.infinity, 77),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Click here to SCAN Checkpoint",
                style: TextStyle(fontSize: 23, color: Colors.white),
              )),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(170, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Panic Button",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                )),
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
        SizedBox(height: 10),
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DailyReportPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 16, 213, 85),
              minimumSize: Size(370, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Incident Report",
              style: TextStyle(fontSize: 20, color: Colors.black),
            ))
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
