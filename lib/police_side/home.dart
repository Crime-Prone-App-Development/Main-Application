import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mainapp/police_side/checkpoint.dart';
import 'package:mainapp/police_side/history.dart';
import 'package:mainapp/police_side/incident.dart';
import 'package:mainapp/police_side/profile.dart';
import 'package:mainapp/police_side/scan.dart';
import 'package:mainapp/police_side/uploadImage.dart';
import 'package:mainapp/token_helper.dart';

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
          _buildAppBar(),
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
        return profilepage();
      case 2:
        return historyPage();

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
                        AssetImage('assets/logos/up_police_logo.png'),
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
                  children: userData.map<Widget>((data) {
                    return Text(data.toString());
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xff7bb4f6),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const ListTile(
        leading: Icon(
          Icons.access_time,
          size: 45,
        ),
        title: Text("SHIFT: 12:00 AM - 8:00 AM"),
        subtitle: Row(
          children: [
            Text(
              "IN-TIME: 12:00 AM",
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(width: 20),
            Text(
              "OUT-TIME: 8:00 AM",
              style: TextStyle(fontSize: 12),
            ),
          ],
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
                trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        checkpoint = true;
                      });
                    },
                    icon: Icon(Icons.arrow_forward_ios)),
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
        )
      ],
    );
  }
}
