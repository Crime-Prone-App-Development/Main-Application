import 'package:flutter/material.dart';
import 'package:mainapp/police_side/notification.dart';
import 'package:mainapp/token_helper.dart';

class Appbar0 extends StatefulWidget {
  const Appbar0({super.key});

  @override
  State<Appbar0> createState() => _Appbar0State();
}

class _Appbar0State extends State<Appbar0> {
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
    {
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationsScreen()),
                    );
                  },
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
                    // children: [Text(userData[2]), Text(userData[2])]
                  ),
                ),
              ),
            ),
          )
        ],
      );
    }
  }
}
