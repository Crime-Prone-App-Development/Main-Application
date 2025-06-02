import 'package:flutter/foundation.dart';
import 'package:mainapp/token_helper.dart';

class UserProvider with ChangeNotifier {
  List<dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  String? _token;
  String? _role;

  List<dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get role => _role;

  Future<void> fetchUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await TokenHelper.getUserData();
      if (userData.isNotEmpty && userData[0] != null) {
        _user = userData;
        _token = userData[0];
        _role = userData.length > 4 ? userData[4] : null;
        _isAuthenticated = true;
        _error = null;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _error = 'Failed to load user: ${e.toString()}';
      _isAuthenticated = false;
      if (kDebugMode) print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> login(String token, String role, ) async {
  //   _token = token;
  //   _role = role;
  //   _user = userData;
  //   _isAuthenticated = true;
  //   await TokenHelper.saveToken(token);
  //   await TokenHelper.saveRole(role);
  //   notifyListeners();
  // }

  // Future<void> logout() async {
  //   _token = null;
  //   _role = null;
  //   _user = null;
  //   _isAuthenticated = false;
  //   await TokenHelper.deleteToken();
  //   notifyListeners();
  // }

  Future<void> checkAuthentication() async {
    final token = await TokenHelper.getToken();
    _isAuthenticated = token != null;
    _token = token;
    if (_isAuthenticated) {
      await fetchUser();
    }
    notifyListeners();
  }

  void updateUser(List<dynamic> newUser) {
    _user = newUser;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _isAuthenticated = false;
    _token = null;
    _role = null;
    notifyListeners();
  }
}