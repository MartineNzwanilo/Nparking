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

  Future<void> fetchVehicles({bool background = false}) async {
    if (!background) {
      _isLoading = true;
      notifyListeners();
    }
    
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
      }
    } catch (e) {
      print('Failed to fetch vehicles: $e');
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
    String? email,
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
        if (email != null && email.isNotEmpty) 'email': email,
        if (company != null && company.isNotEmpty) 'company': company,
        if (color != null && color.isNotEmpty) 'color': color,
        if (makeModel != null && makeModel.isNotEmpty) 'makeModel': makeModel,
        if (finalFront != null && finalFront.isNotEmpty) 'frontImage': finalFront,
        if (finalPlate != null && finalPlate.isNotEmpty) 'plateImage': finalPlate,
        if (finalSide != null && finalSide.isNotEmpty) 'sideImage': finalSide,
      };

      bool forceOffline = SyncService().status == SyncStatus.offline;
      
      if (!forceOffline) {
        try {
          final newVehicle = await _apiService.post('/vehicles', payload);
          _vehicles.insert(0, newVehicle);
        } catch (e) {
          if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('TimeoutException')) {
            forceOffline = true;
          } else {
            rethrow;
          }
        }
      }

      if (forceOffline) {
        final db = await DatabaseHelper.instance.database;
        await db.insert('sync_queue', {
          'endpoint': '/vehicles',
          'method': 'POST',
          'payload': jsonEncode(payload),
          'timestamp': DateTime.now().toIso8601String(),
          'retryCount': 0,
        });
        SyncService().checkPendingItems();
        // Update local state
        final mockVehicle = {
          'id': 'offline_v_${DateTime.now().millisecondsSinceEpoch}',
          ...payload,
        };
        _vehicles.insert(0, mockVehicle);
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
    String? email,
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
        if (email != null) 'email': email,
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
        final index = _vehicles.indexWhere((v) => v['id'] == id);
        if (index != -1) {
          _vehicles[index] = { ..._vehicles[index], ...payload };
        }
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
    String? driverEmail,
    bool? autoSendEmail,
    bool? autoSendSms,
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
        if (driverEmail != null && driverEmail.isNotEmpty) 'driverEmail': driverEmail,
        if (autoSendEmail != null) 'autoSendEmail': autoSendEmail,
        if (autoSendSms != null) 'autoSendSms': autoSendSms,
        if (propertiesLeft != null && propertiesLeft.isNotEmpty) 'propertiesLeft': propertiesLeft,
      };

      bool forceOffline = SyncService().status == SyncStatus.offline;
      Map<String, dynamic>? onlineRes;

      if (!forceOffline) {
        try {
          onlineRes = await _apiService.post('/sessions/checkin', payload);
          await fetchVehicles(background: true);
        } catch (e) {
          if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('TimeoutException')) {
            forceOffline = true;
          } else {
            rethrow;
          }
        }
      }

      if (forceOffline) {
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
          'amountDue': amount,
          'driverName': driverName,
          'driverPhone': driverPhone,
          'driverCompany': driverCompany,
          'propertiesLeft': propertiesLeft,
          'status': 'INSIDE',
          'checkIn': DateTime.now().toIso8601String(),
        };
        
        final index = _vehicles.indexWhere((v) => v['plateNumber'] == plateNumber);
        if (index != -1) {
          _vehicles[index]['sessions'] ??= [];
          _vehicles[index]['sessions'].insert(0, mockSession);
        } else {
          _vehicles.insert(0, {
            'id': 'offline_v_${DateTime.now().millisecondsSinceEpoch}',
            'plateNumber': plateNumber,
            'category': {'name': categoryName},
            'sessions': [mockSession],
          });
        }
        notifyListeners();
        return mockSession;
      }
      
      return Map<String, dynamic>.from(onlineRes!);
    } catch (e) {
      print('Error during checkin: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSessionDetails(String sessionId) async {
    try {
      if (sessionId.startsWith('offline_')) {
        for (var v in _vehicles) {
          if (v['sessions'] != null) {
            for (var s in v['sessions']) {
              if (s['id'] == sessionId) {
                return Map<String, dynamic>.from(s);
              }
            }
          }
        }
        return {
          'id': sessionId,
          'vehicle': {'plateNumber': 'Offline', 'category': {'name': 'Unknown'}},
          'payment': {'amount': 0},
          'driverName': 'Unknown',
        };
      }
      final res = await _apiService.get('/sessions/$sessionId');
      return Map<String, dynamic>.from(res);
    } catch (e) {
      print('Error fetching session details: $e, falling back to local search');
      for (var v in _vehicles) {
        if (v['sessions'] != null) {
          for (var s in v['sessions']) {
            if (s['id'] == sessionId) {
              return Map<String, dynamic>.from(s);
            }
          }
        }
      }
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

      bool forceOffline = SyncService().status == SyncStatus.offline || sessionId.startsWith('offline_');

      if (!forceOffline) {
        try {
          await _apiService.patch('/sessions/checkout/$sessionId', payload);
          await fetchVehicles(background: true);
        } catch (e) {
          if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('TimeoutException')) {
            forceOffline = true;
          } else {
            rethrow;
          }
        }
      }

      if (forceOffline) {
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
        for (var vehicle in _vehicles) {
          if (vehicle['sessions'] != null) {
            final index = (vehicle['sessions'] as List).indexWhere((s) => s['id'] == sessionId);
            if (index != -1) {
              vehicle['sessions'][index]['status'] = 'COMPLETED';
              vehicle['sessions'][index]['checkOut'] = DateTime.now().toIso8601String();
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error during checkout: $e');
      rethrow;
    }
  }
}
