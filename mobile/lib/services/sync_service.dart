import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../core/api_service.dart';
import '../core/database_helper.dart';

enum SyncStatus { synced, syncing, pending, offline }

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final ApiService _apiService = ApiService();

  SyncStatus _status = SyncStatus.synced;
  int _pendingCount = 0;

  SyncStatus get status => _status;
  int get pendingCount => _pendingCount;

  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    checkPendingItems();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final hasConnection = !results.contains(ConnectivityResult.none);
    if (hasConnection) {
      await syncPendingQueue();
    } else {
      _status = SyncStatus.offline;
      await checkPendingItems(); // Update pending count while offline
    }
  }

  Future<void> checkPendingItems() async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sync_queue')) ?? 0;
    _pendingCount = count;
    if (count > 0 && _status != SyncStatus.offline && _status != SyncStatus.syncing) {
      _status = SyncStatus.pending;
    } else if (count == 0) {
      _status = SyncStatus.synced;
    }
    notifyListeners();
  }

  Future<void> syncPendingQueue() async {
    if (_status == SyncStatus.syncing) return;
    
    final db = await DatabaseHelper.instance.database;
    final queue = await db.query('sync_queue', orderBy: 'timestamp ASC');
    
    if (queue.isEmpty) {
      _status = SyncStatus.synced;
      _pendingCount = 0;
      notifyListeners();
      return;
    }

    _status = SyncStatus.syncing;
    _pendingCount = queue.length;
    notifyListeners();

    for (var item in queue) {
      final id = item['id'] as int;
      final endpoint = item['endpoint'] as String;
      final method = item['method'] as String;
      final payloadStr = item['payload'] as String?;
      
      try {
        if (method == 'POST') {
          await _apiService.post(endpoint, payloadStr != null ? jsonDecode(payloadStr) : {});
        } else if (method == 'PATCH') {
          await _apiService.patch(endpoint, payloadStr != null ? jsonDecode(payloadStr) : {});
        }
        
        // Remove from queue on success
        await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        print('Sync failed for item $id: $e');
        // Increment retry count
        final retryCount = (item['retryCount'] as int) + 1;
        await db.update('sync_queue', {'retryCount': retryCount}, where: 'id = ?', whereArgs: [id]);
        break; // Stop syncing on first failure to maintain order, will retry later
      }
    }

    await checkPendingItems();
  }
}
