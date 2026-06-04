import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../services/sync_service.dart';

class ActivityProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _activities = [];
  bool _isLoading = false;

  List<dynamic> get activities => _activities;
  bool get isLoading => _isLoading;

  Future<void> fetchActivities({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (SyncService().status != SyncStatus.offline) {
        String url = '/sessions/activity';
        if (startDate != null && endDate != null) {
          final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
          url += '?startDate=${startDate.toIso8601String()}&endDate=${endOfDay.toIso8601String()}';
        }
        _activities = await _apiService.get(url);
      }
    } catch (e) {
      print('Error fetching activities (offline): $e');
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
