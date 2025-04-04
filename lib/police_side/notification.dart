import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _guardName = "John Doe";
  String _currentDate = "October 15, 2023";
  String _selectedFilter = "All";
  final List<Map<String, String>> _notifications = [
    {
      'date': '10/15/23',
      'time': '9:00 AM',
      'type': 'Alert',
      'message': 'Security breach reported at main gate'
    },
    {
      'date': '10/14/23',
      'time': '8:30 AM',
      'type': 'Update',
      'message': 'New patrol routes have been assigned'
    },
    {
      'date': '10/13/23',
      'time': '7:45 PM',
      'type': 'Reminder',
      'message': 'Shift starts at 8:00 AM tomorrow'
    },
    // Add more notifications as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            _buildFilterChips(),
            SizedBox(height: 20),
            _buildNotificationsTable(),
            SizedBox(height: 20),
            _buildClearButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guard Name: $_guardName'),
            SizedBox(height: 4),
            Text('Date: $_currentDate'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Unread', 'Read', 'Alert'];

    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        return ChoiceChip(
          label: Text(filter),
          selected: _selectedFilter == filter,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = selected ? filter : 'All';
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildNotificationsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Divider(height: 1),
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildTableRow(
                  notification['date']!,
                  notification['time']!,
                  notification['type']!,
                  notification['message']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      color: Colors.grey[200],
      child: Row(
        children: [
          _buildHeaderCell('Date', flex: 1),
          _buildHeaderCell('Time', flex: 1),
          _buildHeaderCell('Type', flex: 1),
          _buildHeaderCell('Message Summary', flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTableRow(String date, String time, String type, String message) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildRowCell(date, flex: 1),
            _buildRowCell(time, flex: 1),
            _buildRowCell(type, flex: 1, isType: true),
            _buildRowCell(message, flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildRowCell(String text, {int flex = 1, bool isType = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: TextStyle(
            color: isType && text == 'Alert' ? Colors.red : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Add clear functionality
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Clear Notifications'),
              content:
                  Text('Are you sure you want to clear all notifications?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _notifications.clear();
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Clear'),
                ),
              ],
            ),
          );
        },
        child: Text('Clear All Notifications'),
      ),
    );
  }
}
