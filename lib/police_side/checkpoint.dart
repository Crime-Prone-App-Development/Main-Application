import 'package:flutter/material.dart';

class CheckpointsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.location_on, size: 24),
              SizedBox(width: 8),
              Text(
                "Total Checkpoints (2)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Checkpoints List
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("1. ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Checkpoint 1 <name>", style: TextStyle(fontSize: 16)),
                  Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text("2. ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Checkpoint 2 <name>", style: TextStyle(fontSize: 16)),
                  Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),

          // Container(
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: ClipRRect(
          //     borderRadius: BorderRadius.circular(8),
          //     child: Image.asset(
          //       'assets/image.png',
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
