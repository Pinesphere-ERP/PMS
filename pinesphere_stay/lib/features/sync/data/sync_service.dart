import '../../../main.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinesphere_stay/objectbox.g.dart';
import '../domain/models/sync_queue_entity.dart';
import '../../bookings/domain/models/booking_entity.dart';
import '../../rooms/domain/models/room_entity.dart';
import '../../guests/domain/models/guest_entity.dart';
import '../../checkin/domain/models/checkin_entity.dart';
import '../../checkout/domain/models/checkout_entity.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final service = SyncService(
    dio: ref.watch(dioClientProvider),
    secureStorage: const FlutterSecureStorage(),
  );
  service.initialize(databaseService.store);
  return service;
}

class SyncService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  late final Store _store;
  late final Box<SyncQueueEntity> _syncQueueBox;
  late final Box<BookingEntity> _bookingBox;
  late final Box<RoomEntity> _roomBox;
  late final Box<GuestEntity> _guestBox;
  late final Box<CheckInEntity> _checkInBox;
  late final Box<CheckOutEntity> _checkOutBox;
  
  bool _isSyncing = false;

  SyncService({required Dio dio, required FlutterSecureStorage secureStorage}) : _dio = dio, _secureStorage = secureStorage;

  Future<void> initialize(Store store) async {
    _store = store;
    _syncQueueBox = _store.box<SyncQueueEntity>();
    _bookingBox = _store.box<BookingEntity>();
    _roomBox = _store.box<RoomEntity>();
    _guestBox = _store.box<GuestEntity>();
    _checkInBox = _store.box<CheckInEntity>();
    _checkOutBox = _store.box<CheckOutEntity>();

    // Listen to network changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      if (hasConnection) {
        triggerSync();
      }
    });

    // Initial sync check
    final results = await Connectivity().checkConnectivity();
    if (!results.contains(ConnectivityResult.none)) {
      triggerSync();
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
    triggerSync();
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      final tenantId = await _secureStorage.read(key: 'tenant_id');
      if (tenantId == null) {
        _isSyncing = false;
        return;
      }
      
      final deviceUid = await _secureStorage.read(key: 'device_uid') ?? 'unknown-device';

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
        
        for (final record in records) {
          final entityType = record['entity_type'];
          final entityId = record['entity_id']; // This is the UUID
          final payload = record['payload'] as Map<String, dynamic>;
          final operation = record['operation'];

          if (operation == 'DELETE') {
            // Not fully implemented for MVP yet, but we'd delete the local record
            continue;
          }
          
          if (entityType == 'Booking') {
            final existing = _bookingBox.query(BookingEntity_.uuid.equals(entityId)).build().findFirst();
            final entity = BookingEntity(
              id: existing?.id ?? 0,
              uuid: entityId,
              propertyId: payload['property_id']?.toString() ?? existing?.propertyId ?? '',
              roomId: payload['room_id']?.toString() ?? existing?.roomId ?? '',
              guestId: payload['guest_id']?.toString() ?? existing?.guestId ?? '',
              guestName: payload['guest_name']?.toString() ?? existing?.guestName ?? '',
              roomNumber: payload['room_number']?.toString() ?? existing?.roomNumber ?? '',
              roomType: payload['room_type']?.toString() ?? existing?.roomType ?? '',
              bookingType: payload['booking_type']?.toString() ?? existing?.bookingType ?? 'online',
              bookingSource: payload['booking_source']?.toString() ?? existing?.bookingSource ?? '',
              checkInDate: payload['check_in_date']?.toString() ?? existing?.checkInDate ?? '',
              checkOutDate: payload['check_out_date']?.toString() ?? existing?.checkOutDate ?? '',
              adults: payload['adults'] != null ? int.parse(payload['adults'].toString()) : (existing?.adults ?? 1),
              children: payload['children'] != null ? int.parse(payload['children'].toString()) : (existing?.children ?? 0),
              infants: payload['infants'] != null ? int.parse(payload['infants'].toString()) : (existing?.infants ?? 0),
              roomRent: payload['room_rent'] != null ? double.parse(payload['room_rent'].toString()) : (existing?.roomRent ?? 0),
              deposit: payload['deposit'] != null ? double.parse(payload['deposit'].toString()) : (existing?.deposit ?? 0),
              discount: payload['discount'] != null ? double.parse(payload['discount'].toString()) : (existing?.discount ?? 0),
              taxes: payload['taxes'] != null ? double.parse(payload['taxes'].toString()) : (existing?.taxes ?? 0),
              totalPayable: payload['total_payable'] != null ? double.parse(payload['total_payable'].toString()) : (existing?.totalPayable ?? 0),
              advancePaid: payload['advance_paid'] != null ? double.parse(payload['advance_paid'].toString()) : (existing?.advancePaid ?? 0),
              pendingAmount: payload['pending_amount'] != null ? double.parse(payload['pending_amount'].toString()) : (existing?.pendingAmount ?? 0),
              extraBed: payload['extra_bed'] == true || (payload['extra_bed']?.toString() == 'true'),
              guestPreferences: payload['guest_preferences']?.toString() ?? existing?.guestPreferences ?? '',
              notes: payload['notes']?.toString() ?? existing?.notes ?? '',
              vehicleNumber: payload['vehicle_number']?.toString() ?? existing?.vehicleNumber ?? '',
              bookingStatus: payload['booking_status']?.toString() ?? existing?.bookingStatus ?? 'confirmed',
              paymentStatus: payload['payment_status']?.toString() ?? existing?.paymentStatus ?? 'pending',
              lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
            );
            _bookingBox.put(entity);
          } else if (entityType == 'Room') {
            final existing = _roomBox.query(RoomEntity_.uuid.equals(entityId)).build().findFirst();
            final entity = RoomEntity(
              id: existing?.id ?? 0,
              uuid: entityId,
              name: payload['room_number']?.toString() ?? existing?.name ?? '',
              type: payload['room_category_id']?.toString() ?? existing?.type ?? '',
              status: payload['occupancy_status']?.toString() ?? payload['status']?.toString() ?? existing?.status ?? 'available',
              pricePerNight: payload['base_price'] != null ? double.parse(payload['base_price'].toString()) : (existing?.pricePerNight ?? 0),
              lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
            );
            _roomBox.put(entity);
          } else if (entityType == 'Guest') {
            final existing = _guestBox.query(GuestEntity_.uuid.equals(entityId)).build().findFirst();
            final entity = GuestEntity(
              id: existing?.id ?? 0,
              uuid: entityId,
              fullName: payload['full_name']?.toString() ?? existing?.fullName ?? '',
              mobile: payload['mobile']?.toString() ?? existing?.mobile ?? '',
              email: payload['email']?.toString() ?? existing?.email ?? '',
              lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
            );
            _guestBox.put(entity);
          } else if (entityType == 'CheckIn') {
            final existing = _checkInBox.query(CheckInEntity_.uuid.equals(entityId)).build().findFirst();
            final entity = CheckInEntity(
              id: existing?.id ?? 0,
              uuid: entityId,
              bookingId: payload['booking_id']?.toString() ?? existing?.bookingId ?? '',
              roomId: payload['room_id']?.toString() ?? existing?.roomId ?? '',
              guestId: payload['guest_id']?.toString() ?? existing?.guestId ?? '',
              checkedInAt: payload['checked_in_at']?.toString() ?? existing?.checkedInAt ?? DateTime.now().toUtc().toIso8601String(),
              idVerified: payload['id_verified'] == true || (payload['id_verified']?.toString() == 'true'),
              status: payload['status']?.toString() ?? existing?.status ?? 'active',
              lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
            );
            _checkInBox.put(entity);
          } else if (entityType == 'CheckOut') {
            final existing = _checkOutBox.query(CheckOutEntity_.uuid.equals(entityId)).build().findFirst();
            final entity = CheckOutEntity(
              id: existing?.id ?? 0,
              uuid: entityId,
              checkinId: payload['checkin_id']?.toString() ?? existing?.checkinId ?? '',
              bookingId: payload['booking_id']?.toString() ?? existing?.bookingId ?? '',
              roomId: payload['room_id']?.toString() ?? existing?.roomId ?? '',
              checkoutTime: payload['checkout_time']?.toString() ?? existing?.checkoutTime ?? DateTime.now().toUtc().toIso8601String(),
              totalAmount: payload['total_amount'] != null ? double.parse(payload['total_amount'].toString()) : (existing?.totalAmount ?? 0),
              paymentStatus: payload['payment_status']?.toString() ?? existing?.paymentStatus ?? 'pending',
              checkoutStatus: payload['checkout_status']?.toString() ?? existing?.checkoutStatus ?? 'pending',
              lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
            );
            _checkOutBox.put(entity);
          }
        }
        
        await _secureStorage.write(key: 'last_sync_timestamp', value: serverTimestamp);
      }
      
    } catch (e) {
      // On failure, items remain in queue. Will retry next time.
      debugPrint("Sync failed: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
