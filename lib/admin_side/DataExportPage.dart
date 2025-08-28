import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mainapp/token_helper.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;
import 'package:syncfusion_officechart/officechart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _isExporting = false;

  String formatDateTime(String? dateTime) {
    // to retunr local time instead of UTC time
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime).toLocal();
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dt);
    } catch (e) {
      return dateTime;
    }
  }
  Future<List<dynamic>> fetchRoute() async {
    try {
      final userData = await TokenHelper.getUserData();
      final token = userData[0];
      final response = await http.get(
        Uri.parse(
            '${dotenv.env["BACKEND_URI"]}/data?startTime=$_startDateTime&endTime=$_endDateTime'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load route: ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body);
      final reports = responseData['data']["reports"] as List;

      if (reports.isEmpty) {
        throw Exception('No route found');
      }

      return reports;
    } catch (e) {
      throw Exception('Error fetching data to be downloaded: $e');
    }
  }

  Future<void> _exportToExcel(
      BuildContext context, DateTime startDate, DateTime endDate) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Reports';

    List<dynamic> reports;
    try {
      reports = await fetchRoute();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reports: ${e.toString()}')),
      );
      return;
    }

    sheet.getRangeByName('A1').setText('Assignment Reports');
    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A1').cellStyle.fontSize = 16;
    sheet.getRangeByName('A1:H1').merge();

    final headers = [
      'User Name',
      'Badge Number',
      'Phone Number',
      'Type',
      'Description',
      'Is Reviewed',
      'Created At',
      'Updated At'
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(3, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(3, i + 1).cellStyle.bold = true;
      sheet.getRangeByIndex(3, i + 1).cellStyle.hAlign = HAlignType.center;
    }

    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      final user = report['user'] ?? {};
      sheet.getRangeByIndex(i + 4, 1).setText(user['name']?.toString() ?? '');
      sheet.getRangeByIndex(i + 4, 2).setText(user['badgeNumber']?.toString() ?? '');
      sheet.getRangeByIndex(i + 4, 3).setText(user['phoneNumber']?.toString() ?? '');
      sheet.getRangeByIndex(i + 4, 4).setText(report['type']?.toString() ?? '');
      sheet.getRangeByIndex(i + 4, 5).setText(report['description']?.toString() ?? '');
      sheet.getRangeByIndex(i + 4, 6).setText(report['isReviewed'] == true ? 'Yes' : 'No');
      sheet.getRangeByIndex(i + 4, 7).setText(formatDateTime(report['createdAt']?.toString())  ?? '');
      sheet.getRangeByIndex(i + 4, 8).setText(formatDateTime(report['updatedAt']?.toString())  ?? '');
    }

    sheet.getRangeByName('A1:H${reports.length + 4}').autoFitColumns();
    sheet.getRangeByName('A3:H${reports.length + 3}').cellStyle.borders.all.lineStyle =
        LineStyle.thin;

    final directory = await _getSaveDirectory();
    final timestamp =
        DateTime.now().toString().replaceAll(RegExp(r'[^\w]'), '_');
    final filePath = '${directory.path}/reports_$timestamp.xlsx';

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await OpenFile.open(filePath);
  }

  Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      final Directory directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory;
      } else {
        return await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (pickedTime == null) return;

    final dateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDateTime = dateTime;
      } else {
        _endDateTime = dateTime;
      }
    });
  }

  String _formatDateTime(DateTime? dt) {
    // for picking the date values
    if (dt == null) return 'Select';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleExport(BuildContext context) async {
    if (_startDateTime == null || _endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both start and end date/time.')),
      );
      return;
    }
    setState(() => _isExporting = true);
    try {
      await _exportToExcel(context, _startDateTime!, _endDateTime!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel file saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving file: ${e.toString()}')),
      );
    }
    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Export Reports", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file_rounded, size: 60, color: Colors.blue[700]),
                  const SizedBox(height: 16),
                  Text(
                    "Export Assignment Reports",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a date range and download the reports in Excel format.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 28),

                  // Date selectors
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateSelector(
                          label: "Start Date & Time",
                          value: _startDateTime,
                          onTap: () => _pickDateTime(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateSelector(
                          label: "End Date & Time",
                          value: _endDateTime,
                          onTap: () => _pickDateTime(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Export button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded, color: Colors.white),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          _isExporting ? "Exporting..." : "Export to Excel",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: Colors.blueAccent,
                        elevation: 4,
                      ),
                      onPressed: _isExporting ? null : () => _handleExport(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, color: Colors.blue),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value == null ? label : _formatDateTime(value),
          style: TextStyle(
            color: value == null ? Colors.grey[600] : Colors.black87,
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        side: BorderSide(color: Colors.blue.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
    );
  }
}
