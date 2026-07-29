import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyToken    = 'jwt_token';
  static const _keyUserId   = 'user_id';
  static const _keyName     = 'user_name';
  static const _keyPhone    = 'user_phone';
  static const _keyEmail    = 'user_email';
  static const _keyRole     = 'user_role';

  static Future<void> saveSession({
    required String token,
    required String userId,
    required String name,
    required String phone,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken,  token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyName,   name);
    await prefs.setString(_keyPhone,  phone);
    await prefs.setString(_keyEmail,  email);
    await prefs.setString(_keyRole,   role);
  }

  static Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) return null;
    return {
      'token':  token,
      'userId': prefs.getString(_keyUserId) ?? '',
      'name':   prefs.getString(_keyName)   ?? '',
      'phone':  prefs.getString(_keyPhone)  ?? '',
      'email':  prefs.getString(_keyEmail)  ?? '',
      'role':   prefs.getString(_keyRole)   ?? '1',
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
