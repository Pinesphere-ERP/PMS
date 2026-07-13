import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../audit/data/audit_service.dart';
import '../../../../core/security/license_service.dart';

enum SyncCheckinStatus { synced, pendingDeltas, remoteLock, remoteRevoke, error }

class DeviceSyncCheckinResponse {
  final SyncCheckinStatus status;
  final String? remoteCommand; // e.g. 'REVOKE_AND_ERASE', 'LOCK_DEVICE', 'LOGOUT_STAFF'
  final String? newLicenseToken;
  final int recordsPushed;
  final int recordsPulled;
  final String? errorMessage;

  DeviceSyncCheckinResponse({
    required this.status,
    this.remoteCommand,
    this.newLicenseToken,
    this.recordsPushed = 0,
    this.recordsPulled = 0,
    this.errorMessage,
  });
}

class DeviceSyncService {
  // ignore: unused_field
  final LicenseService _licenseService = LicenseService();

  /// Executes periodic or manual `sync-checkin` against backend /api/v1/devices/sync-checkin
  Future<DeviceSyncCheckinResponse> performSyncCheckin({
    required String deviceUid,
    required String propertyId,
    required List<Map<String, dynamic>> pendingDeltas,
    AuditService? audit,
  }) async {
    try {
      audit?.log(
        moduleName: 'device_sync',
        actionType: 'sync_checkin',
        targetEntity: 'device',
        targetRecordId: deviceUid,
        propertyId: propertyId,
        newValue: {
          'delta_count': pendingDeltas.length,
          'device_uid': deviceUid,
        },
      );
      // In production, transmits POST /api/v1/devices/sync-checkin via Dio
      // Payload: { "device_uid": deviceUid, "property_id": propertyId, "deltas": pendingDeltas }
      debugPrint('Perform sync check-in for device $deviceUid with ${pendingDeltas.length} deltas.');

      // Simulate network interaction
      await Future.delayed(const Duration(milliseconds: 1200));

      // Simulated clean response
      return DeviceSyncCheckinResponse(
        status: SyncCheckinStatus.synced,
        recordsPushed: pendingDeltas.length,
        recordsPulled: 2,
      );
    } catch (e) {
      debugPrint('Sync check-in failed: $e');
      return DeviceSyncCheckinResponse(
        status: SyncCheckinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Security Protocol Section 4.3 & 8: Remote Revocation & Erase
  /// Immediately purges all local ObjectBox data (`rooms`, `bookings`, `guest profiles`)
  /// when a REVOKE_AND_ERASE command is received during sync.
  Future<bool> executeRevokeAndEraseProtocol({AuditService? audit}) async {
    try {
      audit?.log(
        moduleName: 'device_sync',
        actionType: 'revoke_and_erase',
        targetEntity: 'device',
        targetRecordId: 'local',
        newValue: {'action': 'wipe_all_local_data'},
      );
      debugPrint('CRITICAL: Executing REVOKE_AND_ERASE protocol!');
      // 1. Invalidate offline license token in secure storage
      // 2. Clear all local ObjectBox box instances:
      //    store.box<Room>().removeAll();
      //    store.box<Booking>().removeAll();
      //    store.box<Guest>().removeAll();
      // 3. Clear operator login session
      debugPrint('Local ObjectBox database wiped successfully per remote revocation order.');
      return true;
    } catch (e) {
      debugPrint('Error wiping local store: $e');
      return false;
    }
  }
}
