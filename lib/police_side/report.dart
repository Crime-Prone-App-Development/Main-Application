import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mainapp/police_side/appbar.dart';

import 'package:provider/provider.dart';
import 'package:mainapp/Providers/userProvider.dart';

class DailyReportPage extends StatefulWidget {
  @override
  _DailyReportPageState createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');
  DateTime? _selectedDate;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _totalCheckpointsController =
      TextEditingController();
  final TextEditingController _completedCheckpointsController =
      TextEditingController();
  final TextEditingController _missedCheckpointsController =
      TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, String>> checkpoints = [];
  List<Map<String, String>> incidents = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addCheckpoint() {
    setState(() {
      checkpoints.add({'name': '', 'time': '', 'notes': ''});
    });
  }

  void _addIncident() {
    setState(() {
      incidents.add({'time': '', 'type': '', 'description': '', 'action': ''});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Appbar0(userData: context.watch<UserProvider>().user ?? [],),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 20),
                    _buildDateField(),
                    _buildReadOnlyField('Officer Name', 'Prakhar Mishra'),
                    _buildReadOnlyField('Shift Time', '12:00 AM to 08:00 AM'),
                    _buildReadOnlyField('In-Time', '01:20 AM'),
                    _buildReadOnlyField('Out-Time', '09:30 AM'),
                    _buildLocationField(),
                    _buildNumberInputs(),
                    SizedBox(height: 20),
                    _buildSectionTitle('Checkpoints Visited'),
                    _buildCheckpointsTable(),
                    SizedBox(height: 20),
                    _buildSectionTitle('Incident Reported'),
                    _buildIncidentsTable(),
                    SizedBox(height: 20),
                    _buildNotesField(),
                    SizedBox(height: 30),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Daily Report Submission',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDateField() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.calendar_today),
      title: TextButton(
        onPressed: () => _selectDate(context),
        child: Text(
          _selectedDate != null
              ? _dateFormat.format(_selectedDate!)
              : 'Select Date',
          style: TextStyle(
            fontSize: 16,
            color: _selectedDate != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Location',
        suffixIcon: Icon(Icons.location_on),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required field' : null,
    );
  }

  Widget _buildNumberInputs() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _totalCheckpointsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Total Checkpoints'),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _completedCheckpointsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Completed'),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _missedCheckpointsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Missed'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildCheckpointsTable() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Checkpoint Name')),
              DataColumn(label: Text('Time Visited')),
              DataColumn(label: Text('Notes')),
            ],
            rows: checkpoints.asMap().entries.map((entry) {
              int index = entry.key;
              return DataRow(cells: [
                DataCell(TextField(
                  onChanged: (value) => checkpoints[index]['name'] = value,
                  decoration: InputDecoration(hintText: 'Enter name'),
                )),
                DataCell(TextField(
                  onChanged: (value) => checkpoints[index]['time'] = value,
                  decoration: InputDecoration(hintText: 'HH:MM AM/PM'),
                )),
                DataCell(TextField(
                  onChanged: (value) => checkpoints[index]['notes'] = value,
                  decoration: InputDecoration(hintText: 'Enter notes'),
                )),
              ]);
            }).toList(),
          ),
        ),
        TextButton(
          onPressed: _addCheckpoint,
          child: Text('+ Add Checkpoint'),
        ),
      ],
    );
  }

  Widget _buildIncidentsTable() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Incident Type')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Action Taken')),
            ],
            rows: incidents.asMap().entries.map((entry) {
              int index = entry.key;
              return DataRow(cells: [
                DataCell(TextField(
                  onChanged: (value) => incidents[index]['time'] = value,
                  decoration: InputDecoration(hintText: 'HH:MM AM/PM'),
                )),
                DataCell(TextField(
                  onChanged: (value) => incidents[index]['type'] = value,
                  decoration: InputDecoration(hintText: 'Enter type'),
                )),
                DataCell(TextField(
                  onChanged: (value) => incidents[index]['description'] = value,
                  decoration: InputDecoration(hintText: 'Enter description'),
                )),
                DataCell(TextField(
                  onChanged: (value) => incidents[index]['action'] = value,
                  decoration: InputDecoration(hintText: 'Enter action'),
                )),
              ]);
            }).toList(),
          ),
        ),
        TextButton(
          onPressed: _addIncident,
          child: Text('+ Add Incident'),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Additional Notes',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text('Back', style: TextStyle(color: Colors.black)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _submitReport();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text(
            'Submit Report',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _submitReport() {
    // Handle submission logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Submitted'),
        content: Text('Daily report submitted successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
