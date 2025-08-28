import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mainapp/Providers/userProvider.dart';
import 'package:mainapp/reportsProvider.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> userInfo = [];
  List<dynamic> submittedReports = [];

  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        isStartDate ? _startDate = picked : _endDate = picked;
      });
    }
  }
  @override
  void initState(){
    super.initState();
    setState(() {
      userInfo = context.read<UserProvider>().user!;
    });

  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          // _buildDateRangeSelector(),
          // SizedBox(height: 24),
          // _buildOverviewSection(),
          SizedBox(height: 24),
          _buildSectionTitle('Detailed Patrol Logs'),
          _buildPatrolLogsTable(),
          SizedBox(height: 24),
          _buildSectionTitle('Incident Reports'),
          _buildIncidentReportsTable(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('Guard Name: ${userInfo[2]}'),
        Text('Guard ID: ${userInfo[5]}'),
      ],
    );
  }

  // Widget _buildDateRangeSelector() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _buildDateButton('Start Date', _startDate),
  //       ),
  //       SizedBox(width: 16),
  //       Expanded(
  //         child: _buildDateButton('End Date', _endDate),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildDateButton(String label, DateTime? date) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.grey[200],
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => _selectDate(context, label == 'Start Date'),
      child: Text(
        date != null ? _dateFormat.format(date) : label,
        style: TextStyle(
          color: date != null ? Colors.black : Colors.grey[600],
        ),
      ),
    );
  }

  // Widget _buildOverviewSection() {
  //   return GridView(
  //     shrinkWrap: true,
  //     physics: NeverScrollableScrollPhysics(),
  //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 2,
  //       childAspectRatio: 2,
  //       crossAxisSpacing: 8,
  //       mainAxisSpacing: 8,
  //     ),
  //     children: [
  //       _buildMetricCard('Total Patrols Completed', '0'),
  //       _buildMetricCard('Total Incidents Reported', '0'),
  //       _buildMetricCard('Average Response Time', '0 mins'),
  //       // _buildMetricCard('Overall Satisfaction Rating', '★★★★☆ (80%)'),
  //       _buildMetricCard('Overall Satisfaction Rating', '☆☆☆☆☆ (0%)'),
  //     ],
  //   );
  // }

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

  Widget _buildPatrolLogsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Checkpoints Visited')),
          DataColumn(label: Text('Incidents Reported')),
          DataColumn(label: Text('Note')),
        ],
        rows: [
          // _buildDataRow([
          //   '10/15/2023',
          //   '8:00 AM',
          //   'Checkpoint 1, 2, 3',
          //   '1',
          //   'All clear'
          // ]),
          // _buildDataRow(
          //     ['10/14/2023', '8:00 AM', 'Checkpoint 1, 2', '0', 'No issues']),
          // _buildDataRow([
          //   '10/13/2023',
          //   '8:00 AM',
          //   'Checkpoint 1, 3',
          //   '2',
          //   'Suspicious activity'
          // ]),
        ],
      ),
    );
  }

  Widget _buildIncidentReportsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: [
          DataColumn(label: Text('Date')),
          // DataColumn(label: Text('Time')),
          DataColumn(label: Text('Incident Type')),
          DataColumn(label: Text('Description')),
        ],
        rows: submittedReports.map((report) {
          return _buildDataRow([_formatReportDate(report["createdAt"]) , report["type"], report["description"]]);
        }).toList(),
      ),
    );
  }
  String _formatReportDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  DataRow _buildDataRow(List<String> cells) {
    return DataRow(
      cells: cells.map((cell) => DataCell(Text(cell))).toList(),
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Card(
      margin: EdgeInsets.all(1),
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
