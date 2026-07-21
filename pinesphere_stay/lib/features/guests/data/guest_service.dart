import '../../../main.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/database/dao/guest_dao.dart';
import '../../audit/data/audit_service.dart';
import '../../sync/data/sync_service.dart';
import '../domain/models/guest_entity.dart';

part 'guest_service.g.dart';

@Riverpod(keepAlive: true)
GuestService guestService(Ref ref) {
  final service = GuestService(
    dio: ref.watch(dioClientProvider),
  );
  service.initialize(
    databaseService.guestDao,
    ref.read(syncServiceProvider),
    ref.read(auditServiceProvider),
  );
  return service;
}

class GuestService {
  final Dio _dio;
  late final IGuestDao _guestDao;
  late final SyncService _syncService;
  late final AuditService _audit;

  GuestService({required this._dio});

  void initialize(IGuestDao guestDao, SyncService syncService, AuditService audit) {
    _guestDao = guestDao;
    _syncService = syncService;
    _audit = audit;
  }

  Future<List<dynamic>> searchGuests(String propertyId, {String? search}) async {
    try {
      final queryParams = <String, dynamic>{'property_id': propertyId};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _dio.get('/bookings/guests', queryParameters: queryParams);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      AppLogger.w('searchGuests network failed, falling back to ObjectBox', e);
      return getCachedGuests(propertyId);
    } catch (e) {
      AppLogger.e('searchGuests unexpected error', e);
      return getCachedGuests(propertyId);
    }
  }

  Future<Map<String, dynamic>> createGuest(Map<String, dynamic> data) async {
    try {
      _audit.log(
        moduleName: 'guests',
        actionType: 'create_guest',
        targetEntity: 'guest',
        targetRecordId: data['server_id']?.toString() ?? '',
        propertyId: data['property_id']?.toString(),
        newValue: {
          'full_name': data['full_name'],
          'mobile': data['mobile'],
          'email': data['email'],
          'id_type': data['id_type'],
          'id_number': data['id_number'],
        },
      );
      final response = await _dio.post('/bookings/guests', data: data);
      final body = response.data as Map<String, dynamic>;
      final entity = GuestEntity(
        serverId: body['id']?.toString() ?? data['server_id'] ?? '',
        propertyId: body['property_id']?.toString() ?? data['property_id'] ?? '',
        fullName: body['full_name']?.toString() ?? data['full_name'] ?? '',
        mobile: body['mobile']?.toString() ?? data['mobile'] ?? '',
        email: body['email']?.toString() ?? data['email'] ?? '',
        address: body['address']?.toString() ?? data['address'] ?? '',
        city: body['city']?.toString() ?? data['city'] ?? '',
        state: body['state']?.toString() ?? data['state'] ?? '',
        country: body['country']?.toString() ?? data['country'] ?? '',
        nationality: body['nationality']?.toString() ?? data['nationality'] ?? '',
        dob: body['dob']?.toString() ?? data['dob'] ?? '',
        gender: body['gender']?.toString() ?? data['gender'] ?? '',
        idType: body['id_type']?.toString() ?? data['id_type'] ?? '',
        idNumber: body['id_number']?.toString() ?? data['id_number'] ?? '',
        verificationStatus: body['verification_status']?.toString() ?? 'pending',
        emergencyContactName: body['emergency_contact_name']?.toString() ?? data['emergency_contact_name'] ?? '',
        emergencyContactPhone: body['emergency_contact_phone']?.toString() ?? data['emergency_contact_phone'] ?? '',
        lastModifiedHlc: body['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        syncStatus: 'Synced',
      );
      _guestDao.put(entity);
      return body;
    } on DioException catch (e) {
      AppLogger.w('createGuest network failed, storing locally and queuing sync', e);
      final localUuid = data['server_id'] ?? const Uuid().v4();
      final _ = GuestEntity(
        serverId: localUuid.toString(),
        propertyId: data['property_id'] ?? '',
        fullName: data['full_name'] ?? '',
        mobile: data['mobile'] ?? '',
        email: data['email'] ?? '',
        address: data['address'] ?? '',
        city: data['city'] ?? '',
        state: data['state'] ?? '',
        country: data['country'] ?? '',
        nationality: data['nationality'] ?? '',
        dob: data['dob'] ?? '',
        gender: data['gender'] ?? '',
        idType: data['id_type'] ?? '',
        idNumber: data['id_number'] ?? '',
        verificationStatus: 'pending',
        emergencyContactName: data['emergency_contact_name'] ?? '',
        emergencyContactPhone: data['emergency_contact_phone'] ?? '',
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
        syncStatus: 'Pending',
      );

      _syncService.enqueueMutation(
        entityType: 'Guest',
        entityId: localUuid.toString(),
        operation: 'CREATE',
        payload: {...data, 'server_id': localUuid.toString()},
      );
      return data;
    } catch (e) {
      AppLogger.e('createGuest unexpected error', e);
      rethrow;
    }
  }

  Future<List<GuestEntity>> getCachedGuests(String propertyId) async {
    return _guestDao.findByProperty(propertyId);
  }
}
