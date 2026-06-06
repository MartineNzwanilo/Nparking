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
  static const _userAutoPrintKey = 'auth_user_auto_print';
  static const _userAutoSendEmailKey = 'auth_user_auto_send_email';
  static const _userAutoSendSmsKey = 'auth_user_auto_send_sms';

  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _ready = false;
  String? _token;
  String? _userId;
  String? _name;
  String? _phone;
  String? _role;
  String? _siteId;
  bool _autoPrint = true;
  bool _autoSendEmail = false;
  bool _autoSendSms = false;

  bool get isLoading => _isLoading;
  bool get ready => _ready;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get userId => _userId;
  String? get name => _name;
  String? get phone => _phone;
  String? get role => _role;
  String? get siteId => _siteId;
  bool get autoPrint => _autoPrint;
  bool get autoSendEmail => _autoSendEmail;
  bool get autoSendSms => _autoSendSms;
  bool get isAdmin => _role == 'ADMIN';

  AuthProvider() {
    ApiService.onUnauthorized = () => logout(remote: false);
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
    _autoPrint = prefs.getBool(_userAutoPrintKey) ?? true;
    _autoSendEmail = prefs.getBool(_userAutoSendEmailKey) ?? false;
    _autoSendSms = prefs.getBool(_userAutoSendSmsKey) ?? false;
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
      _autoPrint = user['autoPrint'] as bool? ?? true;
      _autoSendEmail = user['autoSendEmail'] as bool? ?? false;
      _autoSendSms = user['autoSendSms'] as bool? ?? false;
      ApiService.setAuthToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      if (_userId != null) await prefs.setString(_userIdKey, _userId!);
      if (_name != null) await prefs.setString(_userNameKey, _name!);
      if (_phone != null) await prefs.setString(_userPhoneKey, _phone!);
      if (_role != null) await prefs.setString(_userRoleKey, _role!);
      if (_siteId != null) await prefs.setString(_userSiteIdKey, _siteId!);
      await prefs.setBool(_userAutoPrintKey, _autoPrint);
      await prefs.setBool(_userAutoSendEmailKey, _autoSendEmail);
      await prefs.setBool(_userAutoSendSmsKey, _autoSendSms);
      
      // Save for offline login
      await prefs.setString('auth_offline_identifier', identifier.trim());
      await prefs.setString('auth_offline_password', password.trim());
      await prefs.setString('auth_offline_token', _token!);
      if (_userId != null) await prefs.setString('auth_offline_user_id', _userId!);
      if (_name != null) await prefs.setString('auth_offline_user_name', _name!);
      if (_phone != null) await prefs.setString('auth_offline_user_phone', _phone!);
      if (_role != null) await prefs.setString('auth_offline_user_role', _role!);
      if (_siteId != null) await prefs.setString('auth_offline_user_site_id', _siteId!);
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('TimeoutException')) {
        final prefs = await SharedPreferences.getInstance();
        final savedId = prefs.getString('auth_offline_identifier');
        final savedPass = prefs.getString('auth_offline_password');
        
        if (savedId != null && savedPass != null && savedId == identifier.trim() && savedPass == password.trim()) {
          _token = prefs.getString('auth_offline_token') ?? 'offline_token';
          _userId = prefs.getString('auth_offline_user_id');
          _name = prefs.getString('auth_offline_user_name');
          _phone = prefs.getString('auth_offline_user_phone');
          _role = prefs.getString('auth_offline_user_role');
          _siteId = prefs.getString('auth_offline_user_site_id');
          ApiService.setAuthToken(_token);
          
          await prefs.setString(_tokenKey, _token!);
          if (_userId != null) await prefs.setString(_userIdKey, _userId!);
          if (_name != null) await prefs.setString(_userNameKey, _name!);
          if (_role != null) await prefs.setString(_userRoleKey, _role!);
          return; // Successful offline login
        } else {
          throw Exception('Network unavailable and invalid offline credentials. Please connect to internet to login for the first time.');
        }
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout({bool remote = true}) async {
    if (remote && _token != null && _token!.isNotEmpty) {
      try {
        await _api.post('/auth/logout', {});
      } catch (e) {
        print('Backend logout failed: $e');
      }
    }

    _token = null;
    _userId = null;
    _name = null;
    _phone = null;
    _role = null;
    _siteId = null;
    _autoPrint = true;
    _autoSendEmail = false;
    _autoSendSms = false;
    ApiService.setAuthToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userSiteIdKey);
    await prefs.remove(_userAutoPrintKey);
    await prefs.remove(_userAutoSendEmailKey);
    await prefs.remove(_userAutoSendSmsKey);
    notifyListeners();
  }

  Future<void> updatePreferences({
    bool? autoPrint,
    bool? autoSendEmail,
    bool? autoSendSms,
  }) async {
    try {
      final payload = {
        if (autoPrint != null) 'autoPrint': autoPrint,
        if (autoSendEmail != null) 'autoSendEmail': autoSendEmail,
        if (autoSendSms != null) 'autoSendSms': autoSendSms,
      };

      if (autoPrint != null) _autoPrint = autoPrint;
      if (autoSendEmail != null) _autoSendEmail = autoSendEmail;
      if (autoSendSms != null) _autoSendSms = autoSendSms;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      if (autoPrint != null) await prefs.setBool(_userAutoPrintKey, autoPrint);
      if (autoSendEmail != null) await prefs.setBool(_userAutoSendEmailKey, autoSendEmail);
      if (autoSendSms != null) await prefs.setBool(_userAutoSendSmsKey, autoSendSms);

      if (isAuthenticated) {
        await _api.patch('/users/profile/settings', payload);
      }
    } catch (e) {
      print('Failed to sync preferences with server: $e');
    }
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
