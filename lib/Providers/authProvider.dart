import 'package:flutter/foundation.dart';
import '../token_helper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _userRole;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userRole => _userRole;
  String? get token => _token;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userInfo = await TokenHelper.getUserData();
      final token = userInfo.isNotEmpty ? userInfo[0] : null;
      final role = userInfo.length > 4 ? userInfo[4] : null;

      if (token != null && await isValidToken(token)) {
        _isAuthenticated = true;
        _userRole = role;
        _token = token;
      } else {
        _isAuthenticated = false;
        _userRole = null;
        _token = null;
        await TokenHelper.clearData();
      }
    } catch (e) {
      _isAuthenticated = false;
      _userRole = null;
      _token = null;
      await TokenHelper.clearData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await TokenHelper.clearData();
    _isAuthenticated = false;
    _userRole = null;
    _token = null;
    notifyListeners();
  }

  Future<bool> isValidToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env["BACKEND_URI"]}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}