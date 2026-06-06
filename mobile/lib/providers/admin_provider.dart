import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _dashboardMetrics;
  List<dynamic> _cameras = [];
  List<dynamic> _sites = [];
  Map<String, dynamic>? _reportsOverview;
  Map<String, dynamic>? _reportsData;
  Map<String, dynamic>? _systemSettings;
  List<dynamic> _users = [];
  List<dynamic> _accessLogs = [];
  bool _isLoadingMetrics = false;
  bool _isLoadingCameras = false;
  bool _isLoadingSites = false;
  bool _isLoadingReports = false;
  bool _isLoadingSettings = false;
  bool _isLoadingUsers = false;
  bool _isLoadingAccessLogs = false;

  Map<String, dynamic>? get dashboardMetrics => _dashboardMetrics;
  List<dynamic> get cameras => _cameras;
  List<dynamic> get sites => _sites;
  Map<String, dynamic>? get reportsOverview => _reportsOverview;
  Map<String, dynamic>? get reportsData => _reportsData;
  Map<String, dynamic>? get systemSettings => _systemSettings;
  List<dynamic> get users => _users;
  List<dynamic> get accessLogs => _accessLogs;
  bool get isLoadingMetrics => _isLoadingMetrics;
  bool get isLoadingCameras => _isLoadingCameras;
  bool get isLoadingSites => _isLoadingSites;
  bool get isLoadingReports => _isLoadingReports;
  bool get isLoadingSettings => _isLoadingSettings;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingAccessLogs => _isLoadingAccessLogs;
  bool get isLoading => _isLoadingMetrics || _isLoadingCameras || _isLoadingSites || _isLoadingReports || _isLoadingSettings || _isLoadingUsers || _isLoadingAccessLogs;

  String? _selectedSiteIdForSurveillance;
  String? get selectedSiteIdForSurveillance => _selectedSiteIdForSurveillance;

  void setSelectedSiteIdForSurveillance(String? siteId) {
    _selectedSiteIdForSurveillance = siteId;
    _cameras = [];
    _isLoadingCameras = true;
    notifyListeners();
  }

  Future<void> fetchDashboardMetrics({String? siteId}) async {
    _isLoadingMetrics = true;
    notifyListeners();

    try {
      final queryParam = siteId != null && siteId.isNotEmpty ? '?siteId=$siteId' : '';
      _dashboardMetrics = await _apiService.get('/reports/main$queryParam') as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching admin dashboard metrics: $e');
    } finally {
      _isLoadingMetrics = false;
      notifyListeners();
    }
  }

  Future<void> fetchCameras({String? siteId}) async {
    _isLoadingCameras = true;
    notifyListeners();

    try {
      final queryParam = siteId != null && siteId.isNotEmpty ? '?siteId=$siteId' : '';
      _cameras = await _apiService.get('/cameras$queryParam') as List<dynamic>;
    } catch (e) {
      print('Error fetching cameras: $e');
    } finally {
      _isLoadingCameras = false;
      notifyListeners();
    }
  }

  Future<void> fetchSites() async {
    _isLoadingSites = true;
    notifyListeners();

    try {
      _sites = await _apiService.get('/sites') as List<dynamic>;
    } catch (e) {
      print('Error fetching sites: $e');
    } finally {
      _isLoadingSites = false;
      notifyListeners();
    }
  }

  Future<void> createSite(String name, String location, int capacity) async {
    try {
      final newSite = await _apiService.post('/sites', {
        'name': name.trim(),
        'location': location.trim(),
        'capacity': capacity,
      });
      _sites.insert(0, newSite);
      notifyListeners();
    } catch (e) {
      print('Error creating site: $e');
      rethrow;
    }
  }

  Future<void> updateSite(String id, String name, String location, int capacity) async {
    try {
      final updatedSite = await _apiService.patch('/sites/$id', {
        'name': name.trim(),
        'location': location.trim(),
        'capacity': capacity,
      });
      final index = _sites.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _sites[index] = updatedSite;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating site: $e');
      rethrow;
    }
  }

  Future<void> deleteSite(String id) async {
    try {
      await _apiService.delete('/sites/$id');
      _sites.removeWhere((s) => s['id'] == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting site: $e');
      rethrow;
    }
  }

  Future<void> fetchReportsOverview({String? siteId}) async {
    _isLoadingReports = true;
    notifyListeners();

    try {
      final queryParam = siteId != null && siteId.isNotEmpty && siteId != 'all' ? '?siteId=$siteId' : '';
      _reportsOverview = await _apiService.get('/reports/dashboard$queryParam') as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching reports overview: $e');
      _reportsOverview = null;
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  Future<void> fetchReportData({
    required String endpoint,
    required String startDate,
    required String endDate,
    String? siteId,
    String? plate,
  }) async {
    _isLoadingReports = true;
    notifyListeners();

    try {
      final params = <String, String>{
        'startDate': startDate,
        'endDate': endDate,
      };
      if (siteId != null && siteId.isNotEmpty && siteId != 'all') {
        params['siteId'] = siteId;
      }
      if (plate != null && plate.isNotEmpty) {
        params['plate'] = plate;
      }

      final queryString = Uri(queryParameters: params).query;
      final finalQuery = queryString.isNotEmpty ? '?$queryString' : '';

      _reportsData = await _apiService.get('/reports/$endpoint$finalQuery') as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching report data for $endpoint: $e');
      _reportsData = null;
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  Future<void> fetchSystemSettings() async {
    _isLoadingSettings = true;
    notifyListeners();
    try {
      _systemSettings = await _apiService.get('/settings') as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching system settings: $e');
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<void> updateSystemSettings(Map<String, dynamic> data) async {
    _isLoadingSettings = true;
    notifyListeners();
    try {
      _systemSettings = await _apiService.post('/settings', data) as Map<String, dynamic>;
    } catch (e) {
      print('Error updating system settings: $e');
      rethrow;
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsers() async {
    _isLoadingUsers = true;
    notifyListeners();
    try {
      _users = await _apiService.get('/users') as List<dynamic>;
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      final newUser = await _apiService.post('/users', data);
      _users.insert(0, newUser);
      notifyListeners();
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final updatedUser = await _apiService.patch('/users/$id', data);
      final index = _users.indexWhere((u) => u['id'] == id);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _apiService.delete('/users/$id');
      _users.removeWhere((u) => u['id'] == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  Future<void> fetchAccessLogs() async {
    _isLoadingAccessLogs = true;
    notifyListeners();
    try {
      _accessLogs = await _apiService.get('/access-logs') as List<dynamic>;
    } catch (e) {
      print('Error fetching access logs: $e');
    } finally {
      _isLoadingAccessLogs = false;
      notifyListeners();
    }
  }
}
