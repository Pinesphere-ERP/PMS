import '../../../main.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/models/sync_queue_entity.dart';
import '../../bookings/domain/models/booking_entity.dart';
import '../../rooms/domain/models/room_entity.dart';
import '../../guests/domain/models/guest_entity.dart';
import '../../checkin/domain/models/checkin_entity.dart';
import '../../checkout/domain/models/checkout_entity.dart';
import '../../../core/database/dao/sync_queue_dao.dart';
import '../../../core/database/dao/booking_dao.dart';
import '../../../core/database/dao/room_dao.dart';
import '../../../core/database/dao/guest_dao.dart';
import '../../../core/database/dao/checkin_dao.dart';
import '../../../core/database/dao/checkout_dao.dart';
import '../../../core/database/dao/user_dao.dart';
import '../../../core/database/dao/role_dao.dart';
import '../../../core/database/dao/perm_dao.dart';
import '../../../core/database/dao/role_perm_dao.dart';
import '../../../features/user_role_management/domain/entities.dart';
import '../../../core/database/dao/housekeeping_dao.dart';
import '../../housekeeping/domain/models/housekeeping_task_entity.dart';
import 'package:uuid/uuid.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final service = SyncService(
    dio: ref.watch(dioClientProvider),
    secureStorage: const FlutterSecureStorage(),
  );
  service.initialize();
  return service;
}

class SyncService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  
  late final ISyncQueueDao _syncQueueDao;
  late final IBookingDao _bookingDao;
  late final IRoomDao _roomDao;
  late final IGuestDao _guestDao;
  late final ICheckinDao _checkInDao;
  late final ICheckoutDao _checkOutDao;
  late final IUserDao _userDao;
  late final IRoleDao _roleDao;
  late final IPermDao _permDao;
  late final IRolePermDao _rolePermDao;
  
  late final IHousekeepingDao _housekeepingDao;
  
  bool _isSyncing = false;

  SyncService({required this._dio, required this._secureStorage});

  Future<void> initialize() async {
    _syncQueueDao = databaseService.syncQueueDao;
    _housekeepingDao = databaseService.housekeepingDao;
    _bookingDao = databaseService.bookingDao;
    _roomDao = databaseService.roomDao;
    _guestDao = databaseService.guestDao;
    _checkInDao = databaseService.checkinDao;
    _checkOutDao = databaseService.checkoutDao;
    _userDao = databaseService.userDao;
    _roleDao = databaseService.roleDao;
    _permDao = databaseService.permDao;
    _rolePermDao = databaseService.rolePermDao;

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
    required String entityId,
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
      status: 'Pending',
    );
    
    _syncQueueDao.enqueue(item);
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
      _syncQueueDao.retryFailed(); // Retry previously failed pushes
      
      final pendingItems = _syncQueueDao.getPending();
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
          final acceptedIds = List<String>.from(response.data['accepted_ids'] ?? []);
          final conflicts = List<dynamic>.from(response.data['conflicts'] ?? []);
          final failedIds = List<String>.from(response.data['failed_ids'] ?? []);
          
          // Remove accepted and conflicted items from queue
          final toRemoveIds = <int>[];
          for (final item in pendingItems) {
            final uuidStr = item.entityId.toString();
            if (acceptedIds.contains(uuidStr)) {
              toRemoveIds.add(item.id);
            } else if (conflicts.any((c) => c['entity_id'] == uuidStr)) {
              // Server rejected because of conflict (server is newer). Remove local mutation.
              // A subsequent pull will fetch the newer server version.
              toRemoveIds.add(item.id);
            } else if (failedIds.contains(uuidStr)) {
              // Mark as failed
              item.status = 'Failed';
              _syncQueueDao.enqueue(item); // Update
            }
          }
          
          if (toRemoveIds.isNotEmpty) {
            _syncQueueDao.removeMany(toRemoveIds);
          }
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
        
        // Execute atomic block inside a database transaction
        databaseService.runInTransaction(() {
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
              final existing = _bookingDao.getByServerId(entityId);
              final entity = BookingEntity(
                id: existing?.id ?? 0,
                serverId: entityId,
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
                syncStatus: 'Synced',
                lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
              );
              _bookingDao.put(entity);
            } else if (entityType == 'Room') {
              final existing = _roomDao.getByServerId(entityId);
              final entity = RoomEntity(
                id: existing?.id ?? 0,
                serverId: entityId,
                name: payload['room_number']?.toString() ?? existing?.name ?? '',
                type: payload['room_category_id']?.toString() ?? existing?.type ?? '',
                status: payload['occupancy_status']?.toString() ?? payload['status']?.toString() ?? existing?.status ?? 'available',
                pricePerNight: payload['base_price'] != null ? double.parse(payload['base_price'].toString()) : (existing?.pricePerNight ?? 0),
                syncStatus: 'Synced',
                lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
              );
              _roomDao.put(entity);

              final housekeepingStatus = payload['housekeeping_status']?.toString();
              if (housekeepingStatus != null && housekeepingStatus.toLowerCase() != 'clean') {
                final propertyId = payload['property_id']?.toString() ?? existing?.propertyId ?? '';
                final existingTasks = _housekeepingDao.queryTasks(propertyId);
                final hasActiveTask = existingTasks.any((t) => t.roomId == entityId && t.status != 'completed' && t.status != 'closed');
                
                if (!hasActiveTask) {
                  final newTaskId = const Uuid().v4();
                  final newTask = HousekeepingTaskEntity(
                    serverId: newTaskId,
                    roomId: entityId,
                    propertyId: propertyId,
                    roomNumber: entity.name,
                    status: 'pending',
                    priority: 'medium',
                    remarks: 'Generated from sync - $housekeepingStatus',
                    createdAt: DateTime.now().toUtc().toIso8601String(),
                    lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
                  );
                  _housekeepingDao.put(newTask);
                  
                  // Enqueue creation so backend knows about this task
                  enqueueMutation(
                    entityType: 'HousekeepingTask',
                    entityId: newTaskId,
                    operation: 'CREATE',
                    payload: {
                      'uuid': newTaskId,
                      'room_id': entityId,
                      'property_id': propertyId,
                      'room_number': entity.name,
                      'status': 'pending',
                      'priority': 'medium',
                      'remarks': 'Generated from sync - $housekeepingStatus',
                    },
                  );
                }
              }
            } else if (entityType == 'Guest') {
              final existing = _guestDao.getByServerId(entityId);
              final entity = GuestEntity(
                id: existing?.id ?? 0,
                serverId: entityId,
                fullName: payload['full_name']?.toString() ?? existing?.fullName ?? '',
                mobile: payload['mobile']?.toString() ?? existing?.mobile ?? '',
                email: payload['email']?.toString() ?? existing?.email ?? '',
                lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
              );
              _guestDao.put(entity);
            } else if (entityType == 'CheckIn') {
              final existing = _checkInDao.getByServerId(entityId);
              final entity = CheckInEntity(
                id: existing?.id ?? 0,
                serverId: entityId,
                bookingId: payload['booking_id']?.toString() ?? existing?.bookingId ?? '',
                roomId: payload['room_id']?.toString() ?? existing?.roomId ?? '',
                guestId: payload['guest_id']?.toString() ?? existing?.guestId ?? '',
                checkedInAt: payload['checked_in_at']?.toString() ?? existing?.checkedInAt ?? DateTime.now().toUtc().toIso8601String(),
                idVerified: payload['id_verified'] == true || (payload['id_verified']?.toString() == 'true'),
                status: payload['status']?.toString() ?? existing?.status ?? 'active',
                syncStatus: 'Synced',
                lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
              );
              _checkInDao.put(entity);
            } else if (entityType == 'CheckOut') {
              final existing = _checkOutDao.getByServerId(entityId);
              final entity = CheckOutEntity(
                id: existing?.id ?? 0,
                serverId: entityId,
                checkinId: payload['checkin_id']?.toString() ?? existing?.checkinId ?? '',
                bookingId: payload['booking_id']?.toString() ?? existing?.bookingId ?? '',
                roomId: payload['room_id']?.toString() ?? existing?.roomId ?? '',
                checkoutTime: payload['checkout_time']?.toString() ?? existing?.checkoutTime ?? DateTime.now().toUtc().toIso8601String(),
                totalAmount: payload['total_amount'] != null ? double.parse(payload['total_amount'].toString()) : (existing?.totalAmount ?? 0),
                paymentStatus: payload['payment_status']?.toString() ?? existing?.paymentStatus ?? 'pending',
                checkoutStatus: payload['checkout_status']?.toString() ?? existing?.checkoutStatus ?? 'pending',
                syncStatus: 'Synced',
                lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
              );
              _checkOutDao.put(entity);
            } else if (entityType == 'User') {
              final existing = _userDao.getByServerId(entityId);
              final entity = UserEntity(
                id: existing?.id ?? 0,
                serverId: entityId,
                tenantId: payload['tenant_id']?.toString() ?? existing?.tenantId,
                propertyId: payload['property_id']?.toString() ?? existing?.propertyId,
                roleId: payload['role_id']?.toString() ?? existing?.roleId ?? '',
                name: payload['name']?.toString() ?? existing?.name ?? '',
                mobileNumber: payload['mobile_number']?.toString() ?? existing?.mobileNumber,
                email: payload['email']?.toString() ?? existing?.email,
                username: payload['username']?.toString() ?? existing?.username,
                isPrimaryOwner: payload['is_primary_owner'] == true || payload['is_primary_owner']?.toString() == 'true',
                status: payload['status']?.toString() ?? existing?.status ?? 'active',
                lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
                isDeleted: payload['is_deleted'] == true || payload['is_deleted']?.toString() == 'true',
                syncStatus: 'Synced',
              );
              _userDao.put(entity);
            } else if (entityType == 'Role') {
              final existing = _roleDao.getByServerId(entityId);
              final entity = RoleEntity(
                id: existing?.id ?? 0,
                serverId: entityId,
                tenantId: payload['tenant_id']?.toString() ?? existing?.tenantId,
                propertyId: payload['property_id']?.toString() ?? existing?.propertyId,
                roleCode: payload['role_code']?.toString() ?? existing?.roleCode ?? '',
                roleName: payload['role_name']?.toString() ?? existing?.roleName ?? '',
                description: payload['description']?.toString() ?? existing?.description,
                isSystemRole: payload['is_system'] == true || payload['is_system']?.toString() == 'true',
                lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
                isDeleted: payload['is_deleted'] == true || payload['is_deleted']?.toString() == 'true',
                syncStatus: 'Synced',
              );
              _roleDao.put(entity);
            } else if (entityType == 'Permission') {
              final existing = _permDao.getByServerId(entityId);
              final entity = PermissionEntity(
                id: existing?.id ?? 0,
                serverId: entityId,
                permissionCode: payload['permission_code']?.toString() ?? existing?.permissionCode ?? '',
                moduleName: payload['module_name']?.toString() ?? existing?.moduleName ?? '',
                description: payload['description']?.toString() ?? existing?.description,
                lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
                isDeleted: payload['is_deleted'] == true || payload['is_deleted']?.toString() == 'true',
                syncStatus: 'Synced',
              );
              _permDao.put(entity);
            } else if (entityType == 'RolePermission') {
              final existing = _rolePermDao.getByServerId(entityId);
              final entity = RolePermissionEntity(
                id: existing?.id ?? 0,
                serverId: entityId,
                tenantId: payload['tenant_id']?.toString() ?? existing?.tenantId,
                roleId: payload['role_id']?.toString() ?? existing?.roleId ?? '',
                permissionId: payload['permission_id']?.toString() ?? existing?.permissionId ?? '',
                accessLevel: payload['access_level']?.toString() ?? existing?.accessLevel ?? 'read',
                lastModifiedHlc: payload['updated_at']?.toString() ?? existing?.lastModifiedHlc ?? DateTime.now().toUtc().toIso8601String(),
                isDeleted: payload['is_deleted'] == true || payload['is_deleted']?.toString() == 'true',
                syncStatus: 'Synced',
              );
              _rolePermDao.put(entity);
            }
          }
        });
        
        // Update local timestamp only if transaction succeeds
        await _secureStorage.write(key: 'last_sync_timestamp', value: serverTimestamp);
      }
      
    } catch (e) {
      // On failure, items remain in queue (or marked failed)
      debugPrint("Sync failed: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
