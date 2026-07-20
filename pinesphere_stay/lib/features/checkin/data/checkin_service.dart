import '../../../main.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/database/dao/checkin_dao.dart';
import '../../../core/database/dao/room_dao.dart';
import '../../audit/data/audit_service.dart';
import '../../sync/data/sync_service.dart';
import '../domain/models/checkin_entity.dart';

part 'checkin_service.g.dart';

@Riverpod(keepAlive: true)
CheckInService checkInService(Ref ref) {
  final service = CheckInService(
    dio: ref.watch(dioClientProvider),
    auditService: ref.watch(auditServiceProvider),
  );
  service.initialize(
    databaseService.checkinDao,
    databaseService.roomDao,
    ref.read(syncServiceProvider),
  );
  return service;
}

class CheckInService {
  final Dio _dio;
  final AuditService _audit;
  late final ICheckinDao _checkinDao;
  late final IRoomDao _roomDao;
  late final SyncService _syncService;

  CheckInService({required Dio dio, required AuditService auditService})
      : _dio = dio, _audit = auditService;

  void initialize(ICheckinDao checkinDao, IRoomDao roomDao, SyncService syncService) {
    _checkinDao = checkinDao;
    _roomDao = roomDao;
    _syncService = syncService;
  }

  Future<Map<String, dynamic>> performCheckIn(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/checkin', data: data);
      final body = response.data as Map<String, dynamic>;
      final entity = CheckInEntity(
        uuid: body['id']?.toString() ?? data['uuid'] ?? '',
        bookingId: body['booking_id']?.toString() ?? data['booking_id'] ?? '',
        roomId: body['room_id']?.toString() ?? data['room_id'] ?? '',
        guestId: body['guest_id']?.toString() ?? data['guest_id'] ?? '',
        propertyId: body['property_id']?.toString() ?? data['property_id'] ?? '',
        staffId: body['staff_id']?.toString() ?? data['staff_id'] ?? '',
        guestName: body['guest_name']?.toString() ?? data['guest_name'] ?? '',
        roomNumber: body['room_number']?.toString() ?? data['room_number'] ?? '',
        roomType: body['room_type']?.toString() ?? data['room_type'] ?? '',
        deposit: double.tryParse(body['deposit']?.toString() ?? '') ?? data['deposit'] ?? 0,
        advancePaid: double.tryParse(body['advance_paid']?.toString() ?? '') ?? data['advance_paid'] ?? 0,
        idVerified: body['id_verified'] ?? data['id_verified'] ?? false,
        idVerificationNotes: body['id_verification_notes']?.toString() ?? data['id_verification_notes'] ?? '',
        checkedInAt: body['checked_in_at']?.toString() ?? data['checked_in_at'] ?? '',
        status: body['status']?.toString() ?? 'active',
        offlineId: body['offline_id']?.toString() ?? data['offline_id'] ?? '',
        specialRequests: body['special_requests']?.toString() ?? data['special_requests'] ?? '',
        vehicleNumber: body['vehicle_number']?.toString() ?? data['vehicle_number'] ?? '',
        parkingRequired: body['parking_required'] ?? data['parking_required'] ?? false,
        lastModifiedHlc: body['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      );
      _checkinDao.put(entity);
      _updateRoomStatus(data['room_id']?.toString() ?? '', 'Occupied', 'Occupied');
      _audit.log(
        moduleName: 'checkin',
        actionType: 'check_in',
        targetEntity: 'check_in',
        targetRecordId: body['checkin_id']?.toString() ?? body['id']?.toString() ?? '',
        propertyId: data['property_id']?.toString(),
        userId: data['staff_id']?.toString(),
        newValue: {
          'booking_id': data['booking_id'],
          'room_id': data['room_id'],
          'guest_id': data['guest_id'],
          'deposit': data['deposit'],
          'advance_paid': data['advance_paid'],
          'id_verified': data['id_verified'],
        },
      );
      return body;
    } on DioException catch (e) {
      AppLogger.w('performCheckIn network failed, storing locally and queuing sync', e);
      final localUuid = data['uuid'] ?? const Uuid().v4();
      final entity = CheckInEntity(
        uuid: localUuid.toString(),
        bookingId: data['booking_id'] ?? '',
        roomId: data['room_id'] ?? '',
        guestId: data['guest_id'] ?? '',
        propertyId: data['property_id'] ?? '',
        staffId: data['staff_id'] ?? '',
        guestName: data['guest_name'] ?? '',
        roomNumber: data['room_number'] ?? '',
        roomType: data['room_type'] ?? '',
        deposit: (data['deposit'] ?? 0).toDouble(),
        advancePaid: (data['advance_paid'] ?? 0).toDouble(),
        idVerified: data['id_verified'] ?? false,
        idVerificationNotes: data['id_verification_notes'] ?? '',
        checkedInAt: data['checked_in_at'] ?? DateTime.now().toUtc().toIso8601String(),
        status: 'active',
        offlineId: data['offline_id'] ?? '',
        specialRequests: data['special_requests'] ?? '',
        vehicleNumber: data['vehicle_number'] ?? '',
        parkingRequired: data['parking_required'] ?? false,
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
      );
      final localId = _checkinDao.put(entity);
      _updateRoomStatus(data['room_id']?.toString() ?? '', 'Occupied', 'Occupied');
      _syncService.enqueueMutation(
        entityType: 'CheckIn',
        entityId: localUuid.toString(),
        operation: 'CREATE',
        payload: data,
      );
      _audit.log(
        moduleName: 'checkin',
        actionType: 'check_in',
        targetEntity: 'check_in',
        targetRecordId: localUuid,
        propertyId: data['property_id']?.toString(),
        userId: data['staff_id']?.toString(),
        newValue: {
          'booking_id': data['booking_id'],
          'room_id': data['room_id'],
          'guest_id': data['guest_id'],
          'offline': true,
        },
      );
      return data;
    } catch (e) {
      AppLogger.e('performCheckIn unexpected error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> performWalkIn(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/checkin/walkin', data: data);
      final body = response.data as Map<String, dynamic>;
      _audit.log(
        moduleName: 'checkin',
        actionType: 'walk_in',
        targetEntity: 'check_in',
        targetRecordId: body['checkin_id']?.toString() ?? body['id']?.toString() ?? '',
        propertyId: data['property_id']?.toString(),
        userId: data['staff_id']?.toString(),
        newValue: {
          'room_id': data['room_id'],
          'booking_id': data['booking_id'],
          'guest_name': data['guest_name'],
          'advance_paid': data['advance_paid'],
        },
      );
      return body;
    } on DioException catch (e) {
      AppLogger.w('performWalkIn network failed', e);
      rethrow;
    } catch (e) {
      AppLogger.e('performWalkIn unexpected error', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getTodaysCheckIns(String propertyId) async {
    try {
      final response = await _dio.get('/checkin/today', queryParameters: {'property_id': propertyId});
      final List<dynamic> dataList = response.data as List<dynamic>;
      
      final entities = dataList.map<CheckInEntity>((data) => CheckInEntity(
        uuid: data['id']?.toString() ?? data['uuid'] ?? '',
        bookingId: data['booking_id']?.toString() ?? '',
        roomId: data['room_id']?.toString() ?? '',
        guestId: data['guest_id']?.toString() ?? '',
        propertyId: data['property_id']?.toString() ?? '',
        staffId: data['staff_id']?.toString() ?? '',
        guestName: data['guest_name']?.toString() ?? '',
        roomNumber: data['room_number']?.toString() ?? '',
        roomType: data['room_type']?.toString() ?? '',
        deposit: (data['deposit'] ?? 0).toDouble(),
        advancePaid: (data['advance_paid'] ?? 0).toDouble(),
        idVerified: data['id_verified'] ?? false,
        idVerificationNotes: data['id_verification_notes']?.toString() ?? '',
        checkedInAt: data['checked_in_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        status: data['status']?.toString() ?? 'active',
        offlineId: data['offline_id']?.toString() ?? '',
        specialRequests: data['special_requests']?.toString() ?? '',
        vehicleNumber: data['vehicle_number']?.toString() ?? '',
        parkingRequired: data['parking_required'] ?? false,
        lastModifiedHlc: data['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      )).toList();
      
      if (entities.isNotEmpty) {
        _checkinDao.putMany(entities);
      }
      return dataList;
    } on DioException catch (e) {
      AppLogger.w('getTodaysCheckIns network failed, falling back to ObjectBox', e);
      return _checkinDao.findByProperty(propertyId);
    } catch (e) {
      AppLogger.e('getTodaysCheckIns unexpected error', e);
      return _checkinDao.findByProperty(propertyId);
    }
  }

  Future<List<dynamic>> getActiveCheckIns(String propertyId) async {
    try {
      final response = await _dio.get('/checkin/active', queryParameters: {'property_id': propertyId});
      final List<dynamic> dataList = response.data as List<dynamic>;
      
      final entities = dataList.map<CheckInEntity>((data) => CheckInEntity(
        uuid: data['id']?.toString() ?? data['uuid'] ?? '',
        bookingId: data['booking_id']?.toString() ?? '',
        roomId: data['room_id']?.toString() ?? '',
        guestId: data['guest_id']?.toString() ?? '',
        propertyId: data['property_id']?.toString() ?? '',
        staffId: data['staff_id']?.toString() ?? '',
        guestName: data['guest_name']?.toString() ?? '',
        roomNumber: data['room_number']?.toString() ?? '',
        roomType: data['room_type']?.toString() ?? '',
        deposit: (data['deposit'] ?? 0).toDouble(),
        advancePaid: (data['advance_paid'] ?? 0).toDouble(),
        idVerified: data['id_verified'] ?? false,
        idVerificationNotes: data['id_verification_notes']?.toString() ?? '',
        checkedInAt: data['checked_in_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        status: data['status']?.toString() ?? 'active',
        offlineId: data['offline_id']?.toString() ?? '',
        specialRequests: data['special_requests']?.toString() ?? '',
        vehicleNumber: data['vehicle_number']?.toString() ?? '',
        parkingRequired: data['parking_required'] ?? false,
        lastModifiedHlc: data['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      )).toList();
      
      if (entities.isNotEmpty) {
        _checkinDao.putMany(entities);
      }
      return dataList;
    } on DioException catch (e) {
      AppLogger.w('getActiveCheckIns network failed, falling back to ObjectBox', e);
      return _checkinDao.findActiveByProperty(propertyId);
    } catch (e) {
      AppLogger.e('getActiveCheckIns unexpected error', e);
      return _checkinDao.findActiveByProperty(propertyId);
    }
  }

  Future<Map<String, dynamic>> getCheckInDetail(String checkinId) async {
    try {
      final response = await _dio.get('/checkin/$checkinId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.e('getCheckInDetail network failed', e);
      rethrow;
    } catch (e) {
      AppLogger.e('getCheckInDetail unexpected error', e);
      rethrow;
    }
  }

  Future<void> cancelCheckIn(String checkinId) async {
    try {
      await _dio.post('/checkin/$checkinId/cancel');
      _audit.log(
        moduleName: 'checkin',
        actionType: 'cancel_checkin',
        targetEntity: 'check_in',
        targetRecordId: checkinId,
        newValue: {'status': 'cancelled'},
      );
    } on DioException catch (e) {
      AppLogger.w('cancelCheckIn network failed, queuing sync', e);
      _syncService.enqueueMutation(
        entityType: 'CheckIn',
        entityId: checkinId,
        operation: 'UPDATE',
        payload: {'id': checkinId, 'status': 'cancelled'},
      );
      _audit.log(
        moduleName: 'checkin',
        actionType: 'cancel_checkin',
        targetEntity: 'check_in',
        targetRecordId: checkinId,
        newValue: {'status': 'cancelled', 'offline': true},
      );
    } catch (e) {
      AppLogger.e('cancelCheckIn unexpected error', e);
      rethrow;
    }
  }

  void _updateRoomStatus(String roomId, String occupancyStatus, String housekeepingStatus) {
    final room = _roomDao.findByUuid(roomId);
    if (room != null) {
      _roomDao.put(room);
    }
  }
}
