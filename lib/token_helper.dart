import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenHelper {
  // Create an instance of FlutterSecureStorage
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Key for storing the token
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userPhoneNum = 'user_phone';

  // Save token
  static Future<void> saveToken({
    required String token,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    await _storage.write(key: authTokenKey, value: token);
    await _storage.write(key: userIdKey, value: userId);
    await _storage.write(key: userNameKey, value: userName);
    await _storage.write(key: userPhoneNum, value: userPhone);
  }

  // Get token
  static Future<String?> getToken() async {
    return await _storage.read(key: authTokenKey);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: userIdKey);
  }

  // Retrieve user name
  static Future<List<String?>> getUserData() async {
    String ? userName= await _storage.read(key: userNameKey);
    String ? userPhone= await _storage.read(key: userPhoneNum);

    return [userName, userPhone];
    
  }


  // Clear token
  static Future<void> clearToken() async {
    await _storage.delete(key: authTokenKey);
  }
}