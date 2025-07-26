// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';

// class NotificationHistoryScreen extends StatefulWidget {
//   @override
//   _NotificationHistoryScreenState createState() =>
//       _NotificationHistoryScreenState();
// }

// class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
//   late List<Map> history;

//   @override
//   void initState() {
//     super.initState();
//     final box = Hive.box('notifications');
//     history = box.values.cast<Map>().toList().reversed.toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Notification History")),
//       body: history.isEmpty
//           ? Center(child: Text("No notifications received"))
//           : ListView.builder(
//               itemCount: history.length,
//               itemBuilder: (context, index) {
//                 final item = history[index];
//                 return ListTile(
//                   title: Text(item['title']),
//                   subtitle: Text(item['body']),
//                   trailing: Text(
//                     DateTime.parse(item['timestamp'])
//                         .toLocal()
//                         .toString()
//                         .substring(0, 19),
//                     style: TextStyle(fontSize: 12),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
