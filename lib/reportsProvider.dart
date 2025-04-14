import 'package:flutter/foundation.dart';
import 'package:mainapp/token_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportsProvider with ChangeNotifier {
  List<dynamic>? _reports;
  bool _isLoading = false;
  String? _error;

  List<dynamic>? get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await TokenHelper.getToken();
      final response = await http.get(
        Uri.parse('https://patrollingappbackend.onrender.com/api/v1/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData != null && responseData["data"] != null) {
          _reports = responseData["data"];
          _error = null;
        } else {
          _error = 'Invalid response format';
        }
      } else {
        _error = 'Failed to load reports: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            _error = errorData['message'] ?? _error;
          } catch (e) {
            if (kDebugMode) print('Error parsing error response: $e');
          }
        }
      }
    } catch (e) {
      _error = 'Failed to load reports: ${e.toString()}';
      if (kDebugMode) print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearReports() {
    _reports = null;
    notifyListeners();
  }
}