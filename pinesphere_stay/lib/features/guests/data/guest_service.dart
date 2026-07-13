import '../../../main.dart';
import 'package:dio/dio.dart';
import 'package:objectbox/objectbox.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../../objectbox.g.dart';
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
    objectBox.store,
    ref.read(syncServiceProvider),
    ref.read(auditServiceProvider),
  );
  return service;
}

class GuestService {
  final Dio _dio;
  late final Store _store;
  late final Box<GuestEntity> _guestBox;
  late final SyncService _syncService;
  late final AuditService _audit;

  GuestService({required this._dio});

  void initialize(Store store, SyncService syncService, AuditService audit) {
    _store = store;
    _guestBox = _store.box<GuestEntity>();
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
      return getCachedGuests();
    } catch (e) {
      AppLogger.e('searchGuests unexpected error', e);
      return getCachedGuests();
    }
  }

  Future<Map<String, dynamic>> createGuest(Map<String, dynamic> data) async {
    try {
      _audit.log(
        moduleName: 'guests',
        actionType: 'create_guest',
        targetEntity: 'guest',
        targetRecordId: data['uuid']?.toString() ?? '',
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
        uuid: body['id']?.toString() ?? data['uuid'] ?? '',
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
      );
      _guestBox.put(entity);
      return body;
    } on DioException catch (e) {
      AppLogger.w('createGuest network failed, storing locally and queuing sync', e);
      final localUuid = data['uuid'] ?? 'local_${DateTime.now().millisecondsSinceEpoch}';
      final entity = GuestEntity(
        uuid: localUuid.toString(),
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
      );
      final localId = _guestBox.put(entity);
      _syncService.enqueueMutation(
        entityType: 'Guest',
        entityId: localId,
        operation: 'CREATE',
        payload: data,
      );
      return data;
    } catch (e) {
      AppLogger.e('createGuest unexpected error', e);
      rethrow;
    }
  }

  Future<List<GuestEntity>> getCachedGuests() async {
    return _guestBox.getAll();
  }
}
