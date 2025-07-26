import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:mainapp/userProvider.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _guardName = "";
  String _currentDate = DateFormat('MMM d, yyyy').format(DateTime.now());
  String _selectedFilter = "All";

  List<Map> _notificationHistory = [];

  @override
  void initState() {
    super.initState();
    try {
      final userInfo = context.read<UserProvider>().user;
      _guardName = userInfo?[2] ?? "";
    } catch (e) {
      _guardName = "Unknown";
    }
    _loadNotifications();
  }

  void _loadNotifications() {
    final box = Hive.box('notifications');
    setState(() {
      _notificationHistory =
          box.values.cast<Map>().toList().reversed.toList(); // newest first
    });
  }

  void _clearNotifications() async {
    final box = Hive.box('notifications');
    await box.clear();
    _loadNotifications();
  }

  List<Map> _filteredNotifications() {
    if (_selectedFilter == "All") return _notificationHistory;
    return _notificationHistory.where((notif) {
      final type = (notif['type'] ?? "").toString().toLowerCase();
      return type == _selectedFilter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsToShow = _filteredNotifications();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.blue.shade800,
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
            _buildNotificationsTable(notificationsToShow),
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
    final filters = ['All', 'Alert', 'Reminder', 'Update'];

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

  Widget _buildNotificationsTable(List<Map> notifications) {
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
            child: notifications.isEmpty
                ? Center(child: Text("No notifications"))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final dateTime = DateTime.tryParse(notif['timestamp'] ?? "") ?? DateTime.now();
                      final dateStr = DateFormat('MM/dd/yy').format(dateTime);
                      final timeStr = DateFormat('h:mm a').format(dateTime);
                      final type = notif['type'] ?? "General";
                      final msg = notif['body'] ?? "No message";
                      return _buildTableRow(dateStr, timeStr, type, msg);
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
            color: isType && text.toLowerCase() == 'alert'
                ? Colors.red
                : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Clear Notifications'),
              content: Text('Are you sure you want to clear all notifications?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _clearNotifications();
                    Navigator.pop(context);
                  },
                  child: Text('Clear'),
                ),
              ],
            ),
          );
        },
        child: Text('Clear All Notifications'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      ),
    );
  }
}
