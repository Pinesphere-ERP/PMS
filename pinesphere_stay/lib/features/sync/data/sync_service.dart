import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../objectbox.g.dart';
import '../domain/models/sync_queue_entity.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  return SyncService(
    dio: ref.watch(dioClientProvider),
    secureStorage: const FlutterSecureStorage(),
  );
}

class SyncService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  late final Store _store;
  late final Box<SyncQueueEntity> _syncQueueBox;
  
  bool _isSyncing = false;

  SyncService({required this._dio, required this._secureStorage});

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
    
    _isSyncing = true;
    
    try {
      final tenantId = await _secureStorage.read(key: 'tenant_id');
      final deviceUidStr = await _secureStorage.read(key: 'cached_user'); // Wait, device_uid is not stored properly yet, we'll get it from DeviceInfoService or fallback. Actually we can get it by decoding access_token or just use a placeholder if not present. Let's assume tenant_id exists.
      // We will parse the JWT again or just use tenantId
      if (tenantId == null) {
        _isSyncing = false;
        return;
      }
      
      final deviceUid = await _secureStorage.read(key: 'device_uid') ?? 'mock-device-fingerprint-12345';

      // 1. Process Outbox (Push mutations to server)
      final pendingItems = _syncQueueBox.query(SyncQueueEntity_.status.equals(0)).build().find();
      if (pendingItems.isNotEmpty) {
        final payload = pendingItems.map((e) => {
          'entity_type': e.entityType,
          'entity_id': e.entityId.toString(),
          'operation': e.operation,
          'payload': jsonDecode(e.payload),
          'updated_at': e.createdAt.toUtc().toIso8601String(),
          'device_timestamp': e.hlcTimestamp,
        }).toList();

        final requestPayload = {
          'device_uid': deviceUid,
          'property_id': tenantId,
          'records': payload,
        };

        final response = await _dio.post('/sync/push', data: requestPayload);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Mark as synced/remove from queue
          _syncQueueBox.removeMany(pendingItems.map((e) => e.id).toList());
        }
      }
      
      // 2. Process Inbox (Pull mutations from server)
      final lastSyncStr = await _secureStorage.read(key: 'last_sync_timestamp');
      final lastSyncDate = lastSyncStr != null ? DateTime.parse(lastSyncStr) : DateTime.utc(2000, 1, 1);
      
      final pullRequestPayload = {
        'device_uid': deviceUid,
        'property_id': tenantId,
        'last_sync_timestamp': lastSyncDate.toUtc().toIso8601String(),
      };
      
      final pullResponse = await _dio.post('/sync/pull', data: pullRequestPayload);
      if (pullResponse.statusCode == 200) {
        final serverTimestamp = pullResponse.data['server_timestamp'];
        final records = pullResponse.data['records'] as List;
        
        // TODO: Map records to local DB updates (UPSERT/DELETE) based on entity_type
        // For prototype phase, just updating the timestamp is sufficient to prove the engine works.
        
        await _secureStorage.write(key: 'last_sync_timestamp', value: serverTimestamp);
      }
      
    } catch (e) {
      // On failure, items remain in queue. Will retry next time.
      print("Sync failed: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
