import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/database_helper.dart';
import '../services/sync_service.dart';

class VehicleProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _vehicles = [];
  List<dynamic> _categories = [];
  bool _isLoading = false;
  String _overstayTimeLimit = '08:00:00';
  double _overstayFineAmount = 5000.0;

  List<dynamic> get vehicles => _vehicles;
  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;
  String get overstayTimeLimit => _overstayTimeLimit;
  double get overstayFineAmount => _overstayFineAmount;

  Future<void> fetchVehicles() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (SyncService().status != SyncStatus.offline) {
        _vehicles = await _apiService.get('/vehicles');
        _categories = await _apiService.get('/vehicles/categories');
        
        try {
          final settings = await _apiService.get('/settings/parking');
          if (settings != null) {
             _overstayTimeLimit = settings['overstayTimeLimit'] ?? '08:00:00';
             _overstayFineAmount = (settings['overstayFineAmount'] as num?)?.toDouble() ?? 5000.0;
          }
        } catch (e) {
          print('Settings endpoint not found, using default 08:00 AM overstay rules.');
        }
        
        final db = await DatabaseHelper.instance.database;
        await db.transaction((txn) async {
          await txn.delete('categories');
          for (var c in _categories) {
            await txn.insert('categories', {
              'id': c['id'] ?? c['name'],
              'name': c['name'],
              'price': c['price'] ?? 0,
            });
          }
        });
      }
    } catch (e) {
      print('Network failed, falling back to local storage: $e');
      final db = await DatabaseHelper.instance.database;
      _categories = await db.query('categories');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerVehicle(
    String plateNumber, 
    String categoryName, 
    String ownerName, {
    String? phone,
    String? company,
    String? color,
    String? makeModel,
    String? frontImage,
    String? plateImage,
    String? sideImage,
  }) async {
    try {
      String? finalFront = frontImage;
      if (finalFront != null && finalFront.isNotEmpty && !finalFront.startsWith('http')) {
        finalFront = await _apiService.uploadImage(finalFront);
      }
      String? finalPlate = plateImage;
      if (finalPlate != null && finalPlate.isNotEmpty && !finalPlate.startsWith('http')) {
        finalPlate = await _apiService.uploadImage(finalPlate);
      }
      String? finalSide = sideImage;
      if (finalSide != null && finalSide.isNotEmpty && !finalSide.startsWith('http')) {
        finalSide = await _apiService.uploadImage(finalSide);
      }

      final payload = {
        'plateNumber': plateNumber,
        'categoryName': categoryName,
        'ownerName': ownerName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (company != null && company.isNotEmpty) 'company': company,
        if (color != null && color.isNotEmpty) 'color': color,
        if (makeModel != null && makeModel.isNotEmpty) 'makeModel': makeModel,
        if (finalFront != null && finalFront.isNotEmpty) 'frontImage': finalFront,
        if (finalPlate != null && finalPlate.isNotEmpty) 'plateImage': finalPlate,
        if (finalSide != null && finalSide.isNotEmpty) 'sideImage': finalSide,
      };

      if (SyncService().status == SyncStatus.offline) {
        final db = await DatabaseHelper.instance.database;
        await db.insert('sync_queue', {
          'endpoint': '/vehicles',
          'method': 'POST',
          'payload': jsonEncode(payload),
          'timestamp': DateTime.now().toIso8601String(),
          'retryCount': 0,
        });
        SyncService().checkPendingItems();
      } else {
        final newVehicle = await _apiService.post('/vehicles', payload);
        _vehicles.insert(0, newVehicle);
      }
      notifyListeners();
    } catch (e) {
      print('Error registering vehicle: $e');
      rethrow;
    }
  }

  Future<void> updateVehicle(
    String id, {
    String? categoryName, 
    String? ownerName, 
    String? phone,
    String? company,
    String? color,
    String? makeModel,
    String? frontImage,
    String? plateImage,
    String? sideImage,
  }) async {
    try {
      String? finalFront = frontImage;
      if (finalFront != null && finalFront.isNotEmpty && !finalFront.startsWith('http')) {
        finalFront = await _apiService.uploadImage(finalFront);
      }
      String? finalPlate = plateImage;
      if (finalPlate != null && finalPlate.isNotEmpty && !finalPlate.startsWith('http')) {
        finalPlate = await _apiService.uploadImage(finalPlate);
      }
      String? finalSide = sideImage;
      if (finalSide != null && finalSide.isNotEmpty && !finalSide.startsWith('http')) {
        finalSide = await _apiService.uploadImage(finalSide);
      }

      final payload = {
        if (categoryName != null) 'categoryName': categoryName,
        if (ownerName != null) 'ownerName': ownerName,
        if (phone != null) 'phone': phone,
        if (company != null) 'company': company,
        if (color != null) 'color': color,
        if (makeModel != null) 'makeModel': makeModel,
        if (finalFront != null && finalFront.isNotEmpty) 'frontImage': finalFront,
        if (finalPlate != null && finalPlate.isNotEmpty) 'plateImage': finalPlate,
        if (finalSide != null && finalSide.isNotEmpty) 'sideImage': finalSide,
      };

      if (SyncService().status == SyncStatus.offline) {
        final db = await DatabaseHelper.instance.database;
        await db.insert('sync_queue', {
          'endpoint': '/vehicles/$id',
          'method': 'PATCH',
          'payload': jsonEncode(payload),
          'timestamp': DateTime.now().toIso8601String(),
          'retryCount': 0,
        });
        SyncService().checkPendingItems();
      } else {
        final updated = await _apiService.patch('/vehicles/$id', payload);
        final index = _vehicles.indexWhere((v) => v['id'] == id);
        if (index != -1) {
          _vehicles[index] = updated;
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error updating vehicle: $e');
      rethrow;
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await _apiService.delete('/vehicles/$id');
      _vehicles.removeWhere((v) => v['id'] == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting vehicle: $e');
      rethrow;
    }
  }

  Future<void> toggleBlacklist(String id, bool currentStatus) async {
    try {
      final updated = await _apiService.patch('/vehicles/$id', {
        'isBlacklisted': !currentStatus,
      });
      final index = _vehicles.indexWhere((v) => v['id'] == id);
      if (index != -1) {
        _vehicles[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating vehicle: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkInVehicle(
    String plateNumber, 
    String categoryName, 
    double amount, {
    String? driverName,
    String? driverPhone,
    String? driverCompany,
    String? propertiesLeft,
  }) async {
    try {
      final payload = {
        'plateNumber': plateNumber,
        'categoryName': categoryName,
        'amount': amount,
        if (driverName != null && driverName.isNotEmpty) 'driverName': driverName,
        if (driverPhone != null && driverPhone.isNotEmpty) 'driverPhone': driverPhone,
        if (driverCompany != null && driverCompany.isNotEmpty) 'driverCompany': driverCompany,
        if (propertiesLeft != null && propertiesLeft.isNotEmpty) 'propertiesLeft': propertiesLeft,
      };

      if (SyncService().status == SyncStatus.offline) {
        final db = await DatabaseHelper.instance.database;
        final mockId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
        await db.insert('sync_queue', {
          'endpoint': '/sessions/checkin',
          'method': 'POST',
          'payload': jsonEncode(payload),
          'timestamp': DateTime.now().toIso8601String(),
          'retryCount': 0,
        });
        SyncService().checkPendingItems();
        
        final mockSession = {
          'id': mockId,
          'vehicle': {'plateNumber': plateNumber, 'category': {'name': categoryName}},
          'payment': {'amount': amount},
          'checkIn': DateTime.now().toIso8601String(),
        };
        return mockSession;
      } else {
        final res = await _apiService.post('/sessions/checkin', payload);
        await fetchVehicles();
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      print('Error during checkin: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSessionDetails(String sessionId) async {
    try {
      if (sessionId.startsWith('offline_')) {
        return {
          'id': sessionId,
          'vehicle': {'plateNumber': 'Offline', 'category': {'name': 'Unknown'}},
          'payment': {'amount': 0},
        };
      }
      final res = await _apiService.get('/sessions/$sessionId');
      return Map<String, dynamic>.from(res);
    } catch (e) {
      print('Error fetching session details: $e');
      rethrow;
    }
  }

  Future<void> checkOutVehicle(
    String sessionId, {
    double? fineAmount,
    String? actualDepartureTime,
    bool watchmanForgot = false,
  }) async {
    try {
      final payload = {
        if (fineAmount != null) 'fineAmount': fineAmount,
        if (actualDepartureTime != null) 'actualDepartureTime': actualDepartureTime,
        if (watchmanForgot) 'watchmanForgot': watchmanForgot,
      };

      if (SyncService().status == SyncStatus.offline || sessionId.startsWith('offline_')) {
        final db = await DatabaseHelper.instance.database;
        // If it's offline check-out for an online session
        if (!sessionId.startsWith('offline_')) {
          await db.insert('sync_queue', {
            'endpoint': '/sessions/checkout/$sessionId',
            'method': 'PATCH',
            'payload': jsonEncode(payload),
            'timestamp': DateTime.now().toIso8601String(),
            'retryCount': 0,
          });
        }
        SyncService().checkPendingItems();
      } else {
        await _apiService.patch('/sessions/checkout/$sessionId', payload);
        await fetchVehicles();
      }
    } catch (e) {
      print('Error during checkout: $e');
      rethrow;
    }
  }
}
