import '../../../main.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/database/dao/booking_dao.dart';
import '../../audit/data/audit_service.dart';
import '../../sync/data/sync_service.dart';
import '../domain/models/booking_entity.dart';

part 'booking_service.g.dart';

@Riverpod(keepAlive: true)
BookingService bookingService(Ref ref) {
  final service = BookingService(
    dio: ref.watch(dioClientProvider),
    auditService: ref.watch(auditServiceProvider),
  );
  service.initialize(databaseService.bookingDao, ref.read(syncServiceProvider));
  return service;
}

class BookingService {
  final Dio _dio;
  final AuditService _audit;
  late final IBookingDao _bookingDao;
  late final SyncService _syncService;

  BookingService({required this._dio, required AuditService auditService})
      : _audit = auditService;

  void initialize(IBookingDao bookingDao, SyncService syncService) {
    _bookingDao = bookingDao;
    _syncService = syncService;
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/bookings', data: data);
      final body = response.data as Map<String, dynamic>;
      final entity = BookingEntity(
        serverId: body['id']?.toString() ?? data['server_id'] ?? '',
        propertyId: body['property_id']?.toString() ?? data['property_id'] ?? '',
        roomId: body['room_id']?.toString() ?? data['room_id'] ?? '',
        guestId: body['guest_id']?.toString() ?? data['guest_id'] ?? '',
        guestName: body['guest_name']?.toString() ?? data['guest_name'] ?? '',
        roomNumber: body['room_number']?.toString() ?? data['room_number'] ?? '',
        roomType: body['room_type']?.toString() ?? data['room_type'] ?? '',
        bookingType: body['booking_type']?.toString() ?? data['booking_type'] ?? 'online',
        bookingSource: body['booking_source']?.toString() ?? data['booking_source'] ?? '',
        checkInDate: body['check_in_date']?.toString() ?? data['check_in_date'] ?? '',
        checkOutDate: body['check_out_date']?.toString() ?? data['check_out_date'] ?? '',
        adults: int.tryParse(body['adults']?.toString() ?? '') ?? data['adults'] ?? 1,
        children: int.tryParse(body['children']?.toString() ?? '') ?? data['children'] ?? 0,
        infants: int.tryParse(body['infants']?.toString() ?? '') ?? data['infants'] ?? 0,
        roomRent: double.tryParse(body['room_rent']?.toString() ?? '') ?? data['room_rent'] ?? 0,
        deposit: double.tryParse(body['deposit']?.toString() ?? '') ?? data['deposit'] ?? 0,
        discount: double.tryParse(body['discount']?.toString() ?? '') ?? data['discount'] ?? 0,
        taxes: double.tryParse(body['taxes']?.toString() ?? '') ?? data['taxes'] ?? 0,
        totalPayable: double.tryParse(body['total_payable']?.toString() ?? '') ?? data['total_payable'] ?? 0,
        advancePaid: double.tryParse(body['advance_paid']?.toString() ?? '') ?? data['advance_paid'] ?? 0,
        pendingAmount: double.tryParse(body['pending_amount']?.toString() ?? '') ?? data['pending_amount'] ?? 0,
        extraBed: body['extra_bed'] ?? data['extra_bed'] ?? false,
        guestPreferences: body['guest_preferences']?.toString() ?? data['guest_preferences'] ?? '',
        notes: body['notes']?.toString() ?? data['notes'] ?? '',
        vehicleNumber: body['vehicle_number']?.toString() ?? data['vehicle_number'] ?? '',
        bookingStatus: body['booking_status']?.toString() ?? data['booking_status'] ?? 'upcoming',
        paymentStatus: body['payment_status']?.toString() ?? data['payment_status'] ?? 'pending',
        lastModifiedHlc: body['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        syncStatus: 'Synced',
      );
      _bookingDao.put(entity);
      _audit.log(
        moduleName: 'bookings',
        actionType: 'create_booking',
        targetEntity: 'booking',
        targetRecordId: body['id']?.toString() ?? '',
        propertyId: data['property_id']?.toString(),
        newValue: {
          'room_id': data['room_id'],
          'guest_id': data['guest_id'],
          'check_in_date': data['check_in_date'],
          'check_out_date': data['check_out_date'],
          'total_payable': data['total_payable'],
        },
      );
      return body;
    } on DioException catch (e) {
      AppLogger.w('createBooking network failed, storing locally and queuing sync', e);
      final localUuid = data['server_id'] ?? const Uuid().v4();
      final entity = BookingEntity(
        serverId: localUuid.toString(),
        propertyId: data['property_id'] ?? '',
        roomId: data['room_id'] ?? '',
        guestId: data['guest_id'] ?? '',
        guestName: data['guest_name'] ?? '',
        roomNumber: data['room_number'] ?? '',
        roomType: data['room_type'] ?? '',
        bookingType: data['booking_type'] ?? 'online',
        bookingSource: data['booking_source'] ?? '',
        checkInDate: data['check_in_date'] ?? '',
        checkOutDate: data['check_out_date'] ?? '',
        adults: data['adults'] ?? 1,
        children: data['children'] ?? 0,
        infants: data['infants'] ?? 0,
        roomRent: (data['room_rent'] ?? 0).toDouble(),
        deposit: (data['deposit'] ?? 0).toDouble(),
        discount: (data['discount'] ?? 0).toDouble(),
        taxes: (data['taxes'] ?? 0).toDouble(),
        totalPayable: (data['total_payable'] ?? 0).toDouble(),
        advancePaid: (data['advance_paid'] ?? 0).toDouble(),
        pendingAmount: (data['pending_amount'] ?? 0).toDouble(),
        extraBed: data['extra_bed'] ?? false,
        guestPreferences: data['guest_preferences'] ?? '',
        notes: data['notes'] ?? '',
        vehicleNumber: data['vehicle_number'] ?? '',
        bookingStatus: data['booking_status'] ?? 'upcoming',
        paymentStatus: data['payment_status'] ?? 'pending',
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
        syncStatus: 'Pending',
      );
      _bookingDao.put(entity);

      _syncService.enqueueMutation(
        entityType: 'Booking',
        entityId: localUuid.toString(),
        operation: 'CREATE',
        payload: data,
      );
      _audit.log(
        moduleName: 'bookings',
        actionType: 'create_booking',
        targetEntity: 'booking',
        targetRecordId: localUuid.toString(),
        propertyId: data['property_id']?.toString(),
        newValue: {
          'room_id': data['room_id'],
          'guest_id': data['guest_id'],
          'check_in_date': data['check_in_date'],
          'check_out_date': data['check_out_date'],
          'offline': true,
        },
      );
      return data;
    } catch (e) {
      AppLogger.e('createBooking unexpected error', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getBookings(String propertyId, {String? status, String? date}) async {
    try {
      final queryParams = <String, dynamic>{'property_id': propertyId};
      if (status != null) queryParams['status'] = status;
      if (date != null) queryParams['date'] = date;
      final response = await _dio.get('/bookings', queryParameters: queryParams);
      final List<dynamic> dataList = response.data as List<dynamic>;
      
      // Cache data locally for offline use
      final entities = dataList.map<BookingEntity>((data) => BookingEntity(
        serverId: data['id']?.toString() ?? data['server_id'] ?? '',
        propertyId: data['property_id'] ?? '',
        roomId: data['room_id'] ?? '',
        guestId: data['guest_id'] ?? '',
        guestName: data['guest_name'] ?? '',
        roomNumber: data['room_number'] ?? '',
        roomType: data['room_type'] ?? '',
        bookingType: data['booking_type'] ?? 'online',
        bookingSource: data['booking_source'] ?? '',
        checkInDate: data['check_in_date'] ?? '',
        checkOutDate: data['check_out_date'] ?? '',
        adults: data['adults'] ?? 1,
        children: data['children'] ?? 0,
        infants: data['infants'] ?? 0,
        roomRent: (data['room_rent'] ?? 0).toDouble(),
        deposit: (data['deposit'] ?? 0).toDouble(),
        discount: (data['discount'] ?? 0).toDouble(),
        taxes: (data['taxes'] ?? 0).toDouble(),
        totalPayable: (data['total_payable'] ?? 0).toDouble(),
        advancePaid: (data['advance_paid'] ?? 0).toDouble(),
        pendingAmount: (data['pending_amount'] ?? 0).toDouble(),
        extraBed: data['extra_bed'] ?? false,
        guestPreferences: data['guest_preferences'] ?? '',
        notes: data['notes'] ?? '',
        vehicleNumber: data['vehicle_number'] ?? '',
        bookingStatus: data['booking_status'] ?? 'upcoming',
        paymentStatus: data['payment_status'] ?? 'pending',
        lastModifiedHlc: data['last_modified_hlc'] ?? DateTime.now().toUtc().toIso8601String(),
        syncStatus: 'Synced',
      )).toList();
      
      if (entities.isNotEmpty) {
        // Upsert matching UUIDs (would need a custom merge or clear in production, for prototype we put)
        _bookingDao.putMany(entities);
      }
      
      return dataList;
    } on DioException catch (e) {
      AppLogger.w('getBookings network failed, falling back to ObjectBox', e);
      return getCachedBookings(propertyId);
    } catch (e) {
      AppLogger.e('getBookings unexpected error', e);
      return getCachedBookings(propertyId);
    }
  }

  Future<Map<String, dynamic>> getBookingDetail(String bookingId) async {
    try {
      final response = await _dio.get('/bookings/$bookingId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.e('getBookingDetail network failed', e);
      rethrow;
    } catch (e) {
      AppLogger.e('getBookingDetail unexpected error', e);
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _dio.post('/bookings/$bookingId/cancel');
      _audit.log(
        moduleName: 'bookings',
        actionType: 'cancel_booking',
        targetEntity: 'booking',
        targetRecordId: bookingId,
        newValue: {'booking_status': 'cancelled'},
      );
    } on DioException catch (e) {
      AppLogger.w('cancelBooking network failed, queuing sync', e);
      _syncService.enqueueMutation(
        entityType: 'Booking',
        entityId: bookingId,
        operation: 'UPDATE',
        payload: {'id': bookingId, 'booking_status': 'cancelled'},
      );
      _audit.log(
        moduleName: 'bookings',
        actionType: 'cancel_booking',
        targetEntity: 'booking',
        targetRecordId: bookingId,
        newValue: {'booking_status': 'cancelled', 'offline': true},
      );
    } catch (e) {
      AppLogger.e('cancelBooking unexpected error', e);
      rethrow;
    }
  }

  Future<List<BookingEntity>> getCachedBookings(String propertyId) async {
    return _bookingDao.findByProperty(propertyId);
  }
}
