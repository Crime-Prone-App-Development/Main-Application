import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenHelper {
  // Create an instance of FlutterSecureStorage
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Key for storing the token
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userPhoneNum = 'user_phone';
  static const String userRoleKey = 'user_role';
  static const String AssignmentInfoKey = 'assignment_info';

  // Save token
  static Future<void> saveToken({
    required String token,
    required String userId,
    required String userName,
    required String userPhone,
    required String userRole
  }) async {
    await _storage.write(key: authTokenKey, value: token);
    await _storage.write(key: userIdKey, value: userId);
    await _storage.write(key: userNameKey, value: userName);
    await _storage.write(key: userPhoneNum, value: userPhone);
    await _storage.write(key: userRoleKey, value: userRole);
  }

  // Get token
  static Future<String?> getToken() async {
    return await _storage.read(key: authTokenKey);
  }

  // static Future<String?> getUserId() async {
  //   return await _storage.read(key: userIdKey);
  // }

  // Retrieve user name
  static Future<List<String?>> getUserData() async {
    String ? token= await _storage.read(key: authTokenKey);
    String ? userId = await _storage.read(key : userIdKey);
    String ? userName= await _storage.read(key: userNameKey);
    String ? userPhone= await _storage.read(key: userPhoneNum);
    String ? userRole = await _storage.read(key: userRoleKey);
    return [token, userId, userName, userPhone, userRole];
    
  }

  // TODO for saving previously fetched assignment info to show when there is error in fetching details form server
  static Future<void> saveAssignmentInfo(
    List<dynamic> info
  ) async {
    final value = json.encode(info);
    await _storage.write(key: AssignmentInfoKey, value: value);
  }

  static Future<List<dynamic>> getAssignments() async {
    final value = await _storage.read(key: AssignmentInfoKey);
    if (value == null) return [];
    // Convert the JSON string back to a List
    return jsonDecode(value) as List<dynamic>;
  }

  // Delete an array
  static Future<void> deleteAssignments() async {
    await _storage.delete(key: AssignmentInfoKey);
  }


  // Clear token
  static Future<void> clearToken() async {
    await _storage.delete(key: authTokenKey);
  }
}