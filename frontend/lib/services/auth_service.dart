import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<void> saveLoginData(
      int userId, String username, String role, String nama) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('userId', userId);
    await prefs.setString('username', username);
    await prefs.setString('role', role);
    await prefs.setString('nama', nama);
  }

  Future<Map<String, dynamic>> getLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
      'userId': prefs.getInt('userId') ?? 0,
      'username': prefs.getString('username') ?? '',
      'role': prefs.getString('role') ?? '',
      'nama': prefs.getString('nama') ?? '',
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
