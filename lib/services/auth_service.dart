import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService apiService;

  bool _isAuthenticated = false;
  String? _token;
  String? _userId;
  String? _username;
  String? _userRole;
  String? _fullName;
  String? _email;

  AuthService({required this.apiService}) {
    _loadFromStorage();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  String get userRole => _userRole ?? '';
  String? get fullName => _fullName;
  String? get email => _email;
  String get userName => _fullName ?? _username ?? 'User';

  // Load saved auth data from local storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _userId = prefs.getString('user_id');
      _username = prefs.getString('username');
      _userRole = prefs.getString('user_role');
      _fullName = prefs.getString('full_name');
      _email = prefs.getString('email');

      if (_token != null) {
        _isAuthenticated = true;
        apiService.setAuthToken(_token!);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from storage: $e');
    }
  }

  // Login method
  Future<bool> login(String username, String password) async {
    try {
      final result = await apiService.login(username, password);

      if (result['success'] == true) {
        _token = result['token'];
        final user = result['user'];

        _userId = user['id'].toString();
        _username = user['username'];
        _userRole = user['role'];
        _fullName = user['full_name'];
        _email = user['email'];
        _isAuthenticated = true;

        apiService.setAuthToken(_token!);

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_id', _userId!);
        await prefs.setString('username', _username!);
        await prefs.setString('user_role', _userRole!);
        await prefs.setString('full_name', _fullName!);
        await prefs.setString('email', _email!);

        notifyListeners();
        return true;
      } else {
        debugPrint('Login failed: ${result['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _userId = null;
    _username = null;
    _userRole = null;
    _fullName = null;
    _email = null;

    apiService.clearAuthToken();

    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('user_role');
    await prefs.remove('full_name');
    await prefs.remove('email');

    notifyListeners();
  }
}
