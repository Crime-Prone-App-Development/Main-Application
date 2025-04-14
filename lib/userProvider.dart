import 'package:flutter/foundation.dart';
import 'package:mainapp/token_helper.dart';

class UserProvider with ChangeNotifier {
  List<dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  List<dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Replace with your actual API call
      final user = await TokenHelper.getUserData();
      _user = user;
      _error = null;
    } catch (e) {
      _error = 'Failed to load user: ${e.toString()}';
      if (kDebugMode) print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateUser(List<dynamic> newUser) {
    _user = newUser;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}