import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../services/sync_service.dart';

class ActivityProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _activities = [];
  bool _isLoading = false;

  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  List<dynamic> get activities => _activities;
  bool get isLoading => _isLoading;

  Future<void> fetchActivities({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    notifyListeners();
    
    if (startDate != null) _currentStartDate = startDate;
    if (endDate != null) _currentEndDate = endDate;

    final start = _currentStartDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = _currentEndDate ?? DateTime.now();

    try {
      final startUtc = DateTime(start.year, start.month, start.day, 0, 0, 0).toUtc();
      final endUtc = DateTime(end.year, end.month, end.day, 23, 59, 59, 999).toUtc();
      final url = '/sessions/activity?startDate=${startUtc.toIso8601String()}&endDate=${endUtc.toIso8601String()}';
      _activities = await _apiService.get(url);
    } catch (e) {
      print('Error fetching activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivity(String sessionId) async {
    try {
      if (SyncService().status == SyncStatus.offline) return;
      await _apiService.delete('/sessions/$sessionId');
      _activities.removeWhere((a) => a['id'].toString().contains(sessionId));
      notifyListeners();
    } catch (e) {
      print('Error deleting activity: $e');
      rethrow;
    }
  }

  Future<void> bulkDeleteActivities(List<String> sessionIds) async {
    try {
      if (SyncService().status == SyncStatus.offline) return;
      await _apiService.post('/sessions/bulk-delete', {'ids': sessionIds});
      _activities.removeWhere((a) {
        return sessionIds.any((id) => a['id'].toString().contains(id));
      });
      notifyListeners();
    } catch (e) {
      print('Error bulk deleting activities: $e');
      rethrow;
    }
  }
}
