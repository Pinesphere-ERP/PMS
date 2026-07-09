import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/objectbox.dart';
import '../../../core/network/dio_client.dart';
import '../../../objectbox.g.dart';
import '../domain/models/sync_queue_entity.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  return SyncService(
    dio: ref.watch(dioClientProvider),
  );
}

class SyncService {
  final Dio _dio;
  late final Store _store;
  late final Box<SyncQueueEntity> _syncQueueBox;
  
  bool _isSyncing = false;

  SyncService({required Dio dio}) : _dio = dio;

  Future<void> initialize(Store store) async {
    _store = store;
    _syncQueueBox = _store.box<SyncQueueEntity>();

    // Listen to network changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      if (hasConnection) {
        _triggerSync();
      }
    });

    // Initial sync check
    final results = await Connectivity().checkConnectivity();
    if (!results.contains(ConnectivityResult.none)) {
      _triggerSync();
    }
  }

  /// Queues a local mutation to be synced to the backend
  void enqueueMutation({
    required String entityType,
    required int entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) {
    // Generate an HLC timestamp (simplified for prototype)
    final hlcTimestamp = DateTime.now().toUtc().toIso8601String();

    final item = SyncQueueEntity(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: jsonEncode(payload),
      hlcTimestamp: hlcTimestamp,
      status: 0, // Pending
    );
    
    _syncQueueBox.put(item);
    _triggerSync();
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    
    final pendingItems = _syncQueueBox.query(SyncQueueEntity_.status.equals(0)).build().find();
    if (pendingItems.isEmpty) return;

    _isSyncing = true;
    
    try {
      // 1. Process Outbox (Push mutations to server)
      final payload = pendingItems.map((e) => {
        'id': e.id,
        'entity_type': e.entityType,
        'entity_id': e.entityId,
        'operation': e.operation,
        'payload': jsonDecode(e.payload),
        'hlc_timestamp': e.hlcTimestamp,
      }).toList();

      final response = await _dio.post('/sync/push', data: {'mutations': payload});
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mark as synced/remove from queue
        _syncQueueBox.removeMany(pendingItems.map((e) => e.id).toList());
      }
      
      // 2. Process Inbox (Pull mutations from server)
      // Implementation pending FastAPI endpoint availability...
      
    } catch (e) {
      // On failure, items remain in queue. Will retry next time.
      print("Sync failed: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
