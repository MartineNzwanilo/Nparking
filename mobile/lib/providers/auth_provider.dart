import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _userNameKey = 'auth_user_name';
  static const _userPhoneKey = 'auth_user_phone';
  static const _userRoleKey = 'auth_user_role';
  static const _userSiteIdKey = 'auth_user_site_id';

  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _ready = false;
  String? _token;
  String? _userId;
  String? _name;
  String? _phone;
  String? _role;
  String? _siteId;

  bool get isLoading => _isLoading;
  bool get ready => _ready;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get userId => _userId;
  String? get name => _name;
  String? get phone => _phone;
  String? get role => _role;
  String? get siteId => _siteId;
  bool get isAdmin => _role == 'ADMIN';

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getString(_userIdKey);
    _name = prefs.getString(_userNameKey);
    _phone = prefs.getString(_userPhoneKey);
    _role = prefs.getString(_userRoleKey);
    _siteId = prefs.getString(_userSiteIdKey);
    ApiService.setAuthToken(_token);
    _ready = true;
    notifyListeners();
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.post('/auth/login', {
        'identifier': identifier.trim(),
        'password': password.trim(),
      }) as Map<String, dynamic>;

      final token = response['accessToken']?.toString() ?? '';
      final user = (response['user'] as Map?)?.cast<String, dynamic>() ?? {};
      if (token.isEmpty) {
        throw Exception('Invalid authentication response');
      }

      _token = token;
      _userId = user['id']?.toString();
      _name = user['name']?.toString();
      _phone = user['phone']?.toString();
      _role = user['role']?.toString();
      _siteId = user['siteId']?.toString();
      ApiService.setAuthToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      if (_userId != null) await prefs.setString(_userIdKey, _userId!);
      if (_name != null) await prefs.setString(_userNameKey, _name!);
      if (_phone != null) await prefs.setString(_userPhoneKey, _phone!);
      if (_role != null) await prefs.setString(_userRoleKey, _role!);
      if (_siteId != null) await prefs.setString(_userSiteIdKey, _siteId!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null && _token!.isNotEmpty) {
        await _api.post('/auth/logout', {});
      }
    } catch (e) {
      // Fail-safe: ignore connection errors on logout to allow offline/clean logout
      print('Backend logout failed: $e');
    }

    _token = null;
    _userId = null;
    _name = null;
    _phone = null;
    _role = null;
    _siteId = null;
    ApiService.setAuthToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userSiteIdKey);
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post('/auth/forgot-password', {
        'email': email.trim(),
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post('/auth/reset-password', {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword.trim(),
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
