import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:objectbox/objectbox.dart';
import '../queue/sync_operation.dart';

class SyncOrchestrator {
  final Box<SyncOperation> syncBox;
  final Dio apiClient;
  final String deviceUid;
  final String propertyId;

  SyncOrchestrator({
    required this.syncBox,
    required this.apiClient,
    required this.deviceUid,
    required this.propertyId,
  });

  /// Starts the synchronization process (Push then Pull)
  Future<void> sync() async {
    try {
      await _pushChanges();
      await _pullChanges();
    } catch (e) {
      print('Sync failed: $e');
      // Retry logic or conflict handling can be added here
    }
  }

  /// Push local changes (Outbox) to the cloud
  Future<void> _pushChanges() async {
    // 1. Get all pending operations
    final pendingOps = syncBox.query(SyncOperation_.status.equals('pending')).build().find();
    if (pendingOps.isEmpty) return;

    // 2. Mark as in_progress
    for (var op in pendingOps) {
      op.status = 'in_progress';
    }
    syncBox.putMany(pendingOps);

    // 3. Prepare payload
    final records = pendingOps.map((op) => {
      'entity_type': op.entityType,
      'entity_id': op.entityId,
      'operation': op.operationType.toUpperCase(),
      'payload': jsonDecode(op.payload),
      'updated_at': op.createdAt.toIso8601String(),
      'device_timestamp': DateTime.now().toUtc().toIso8601String(),
    }).toList();

    // 4. Send to API
    try {
      final response = await apiClient.post('/api/v1/sync/push', data: {
        'device_uid': deviceUid,
        'property_id': propertyId,
        'records': records,
      });

      if (response.statusCode == 200) {
        final acceptedIds = List<String>.from(response.data['accepted_ids'] ?? []);
        final failedIds = List<String>.from(response.data['failed_ids'] ?? []);
        
        // Remove accepted from local queue
        final toRemove = pendingOps.where((op) => acceptedIds.contains(op.entityId)).map((op) => op.id).toList();
        syncBox.removeMany(toRemove);

        // Mark failed for retry
        final toFail = pendingOps.where((op) => failedIds.contains(op.entityId)).toList();
        for (var op in toFail) {
          op.status = 'pending';
          op.retryCount += 1;
        }
        syncBox.putMany(toFail);
      }
    } catch (e) {
      // Revert to pending on network error
      for (var op in pendingOps) {
        op.status = 'pending';
        op.retryCount += 1;
      }
      syncBox.putMany(pendingOps);
      rethrow;
    }
  }

  /// Pull changes from cloud and apply to local DB
  Future<void> _pullChanges() async {
    // Fetch last sync timestamp from local secure storage/preferences
    // Stubbed to 1 day ago for this implementation
    final lastSyncTimestamp = DateTime.now().subtract(const Duration(days: 1)).toUtc().toIso8601String();

    final response = await apiClient.post('/api/v1/sync/pull', data: {
      'device_uid': deviceUid,
      'property_id': propertyId,
      'last_sync_timestamp': lastSyncTimestamp,
    });

    if (response.statusCode == 200) {
      final records = response.data['records'] as List;
      for (var record in records) {
        // Here we would apply the changes to the respective ObjectBox entities
        // Example: if (record['entity_type'] == 'Room') { roomBox.put(...) }
        print('Pulled update for ${record['entity_type']} - ${record['entity_id']}');
      }
      // Update last sync timestamp in preferences here
    }
  }
}
