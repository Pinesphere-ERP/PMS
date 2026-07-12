import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/objectbox.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../../objectbox.g.dart';
import '../../audit/data/audit_service.dart';
import '../../rooms/domain/models/room_entity.dart';
import '../../sync/data/sync_service.dart';
import '../domain/models/checkout_entity.dart';

part 'checkout_service.g.dart';

@Riverpod(keepAlive: true)
CheckOutService checkOutService(Ref ref) {
  return CheckOutService(
    dio: ref.watch(dioClientProvider),
    auditService: ref.watch(auditServiceProvider),
  );
}

class CheckOutService {
  final Dio _dio;
  final AuditService _audit;
  late final Store _store;
  late final Box<CheckOutEntity> _checkoutBox;
  late final Box<RoomEntity> _roomBox;
  late final SyncService _syncService;

  CheckOutService({required Dio dio, required AuditService auditService})
      : _dio = dio,
        _audit = auditService;

  void initialize(Store store, SyncService syncService) {
    _store = store;
    _checkoutBox = _store.box<CheckOutEntity>();
    _roomBox = _store.box<RoomEntity>();
    _syncService = syncService;
  }

  Future<Map<String, dynamic>> performCheckOut(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/checkout/', data: data);
      final body = response.data as Map<String, dynamic>;
      final entity = CheckOutEntity(
        uuid: body['id']?.toString() ?? data['uuid'] ?? '',
        checkinId: body['checkin_id']?.toString() ?? data['checkin_id'] ?? '',
        bookingId: body['booking_id']?.toString() ?? data['booking_id'] ?? '',
        roomId: body['room_id']?.toString() ?? data['room_id'] ?? '',
        propertyId: body['property_id']?.toString() ?? data['property_id'] ?? '',
        staffId: body['staff_id']?.toString() ?? data['staff_id'] ?? '',
        guestName: body['guest_name']?.toString() ?? data['guest_name'] ?? '',
        roomNumber: body['room_number']?.toString() ?? data['room_number'] ?? '',
        checkoutTime: body['checkout_time']?.toString() ?? data['checkout_time'] ?? '',
        roomCharges: double.tryParse(body['room_charges']?.toString() ?? '') ?? data['room_charges'] ?? 0,
        restaurantCharges: double.tryParse(body['restaurant_charges']?.toString() ?? '') ?? data['restaurant_charges'] ?? 0,
        laundryCharges: double.tryParse(body['laundry_charges']?.toString() ?? '') ?? data['laundry_charges'] ?? 0,
        minibarCharges: double.tryParse(body['minibar_charges']?.toString() ?? '') ?? data['minibar_charges'] ?? 0,
        damageCharges: double.tryParse(body['damage_charges']?.toString() ?? '') ?? data['damage_charges'] ?? 0,
        miscellaneousCharges: double.tryParse(body['miscellaneous_charges']?.toString() ?? '') ?? data['miscellaneous_charges'] ?? 0,
        discount: double.tryParse(body['discount']?.toString() ?? '') ?? data['discount'] ?? 0,
        gst: double.tryParse(body['gst']?.toString() ?? '') ?? data['gst'] ?? 0,
        totalAmount: double.tryParse(body['total_amount']?.toString() ?? '') ?? data['total_amount'] ?? 0,
        advancePaid: double.tryParse(body['advance_paid']?.toString() ?? '') ?? data['advance_paid'] ?? 0,
        remainingBalance: double.tryParse(body['remaining_balance']?.toString() ?? '') ?? data['remaining_balance'] ?? 0,
        refundAmount: double.tryParse(body['refund_amount']?.toString() ?? '') ?? data['refund_amount'] ?? 0,
        paymentStatus: body['payment_status']?.toString() ?? data['payment_status'] ?? 'pending',
        keyReturned: body['key_returned'] ?? data['key_returned'] ?? false,
        idReturned: body['id_returned'] ?? data['id_returned'] ?? false,
        feedbackSubmitted: body['feedback_submitted'] ?? data['feedback_submitted'] ?? false,
        remarks: body['remarks']?.toString() ?? data['remarks'] ?? '',
        checkoutStatus: body['checkout_status']?.toString() ?? 'completed',
        lastModifiedHlc: body['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      );
      _checkoutBox.put(entity);
      _updateRoomToDirty(data['room_id']?.toString() ?? '');
      _audit.log(
        moduleName: 'checkout',
        actionType: 'check_out',
        targetEntity: 'check_out',
        targetRecordId: body['id']?.toString() ?? '',
        propertyId: data['property_id']?.toString(),
        userId: data['staff_id']?.toString(),
        newValue: {
          'booking_id': data['booking_id'],
          'checkin_id': data['checkin_id'],
          'room_id': data['room_id'],
          'total_amount': data['total_amount'],
          'payment_status': data['payment_status'],
        },
      );
      return body;
    } on DioException catch (e) {
      AppLogger.w('performCheckOut network failed, storing locally and queuing sync', e);
      final localUuid = data['uuid'] ?? 'local_${DateTime.now().millisecondsSinceEpoch}';
      final entity = CheckOutEntity(
        uuid: localUuid.toString(),
        checkinId: data['checkin_id'] ?? '',
        bookingId: data['booking_id'] ?? '',
        roomId: data['room_id'] ?? '',
        propertyId: data['property_id'] ?? '',
        staffId: data['staff_id'] ?? '',
        guestName: data['guest_name'] ?? '',
        roomNumber: data['room_number'] ?? '',
        checkoutTime: data['checkout_time'] ?? DateTime.now().toUtc().toIso8601String(),
        roomCharges: (data['room_charges'] ?? 0).toDouble(),
        restaurantCharges: (data['restaurant_charges'] ?? 0).toDouble(),
        laundryCharges: (data['laundry_charges'] ?? 0).toDouble(),
        minibarCharges: (data['minibar_charges'] ?? 0).toDouble(),
        damageCharges: (data['damage_charges'] ?? 0).toDouble(),
        miscellaneousCharges: (data['miscellaneous_charges'] ?? 0).toDouble(),
        discount: (data['discount'] ?? 0).toDouble(),
        gst: (data['gst'] ?? 0).toDouble(),
        totalAmount: (data['total_amount'] ?? 0).toDouble(),
        advancePaid: (data['advance_paid'] ?? 0).toDouble(),
        remainingBalance: (data['remaining_balance'] ?? 0).toDouble(),
        refundAmount: (data['refund_amount'] ?? 0).toDouble(),
        paymentStatus: data['payment_status'] ?? 'pending',
        keyReturned: data['key_returned'] ?? false,
        idReturned: data['id_returned'] ?? false,
        feedbackSubmitted: data['feedback_submitted'] ?? false,
        remarks: data['remarks'] ?? '',
        checkoutStatus: 'completed',
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
      );
      final localId = _checkoutBox.put(entity);
      _updateRoomToDirty(data['room_id']?.toString() ?? '');
      _syncService.enqueueMutation(
        entityType: 'CheckOut',
        entityId: localId,
        operation: 'CREATE',
        payload: data,
      );
      _audit.log(
        moduleName: 'checkout',
        actionType: 'check_out',
        targetEntity: 'check_out',
        targetRecordId: localUuid.toString(),
        propertyId: data['property_id']?.toString(),
        userId: data['staff_id']?.toString(),
        newValue: {
          'booking_id': data['booking_id'],
          'checkin_id': data['checkin_id'],
          'room_id': data['room_id'],
          'total_amount': data['total_amount'],
          'offline': true,
        },
      );
      return data;
    } catch (e) {
      AppLogger.e('performCheckOut unexpected error', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getPendingCheckOuts(String propertyId) async {
    try {
      final response = await _dio.get('/checkout/pending', queryParameters: {'property_id': propertyId});
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      AppLogger.w('getPendingCheckOuts network failed, falling back to ObjectBox', e);
      return _checkoutBox.query(
        CheckOutEntity_.propertyId.equals(propertyId) & CheckOutEntity_.checkoutStatus.equals('pending'),
      ).build().find();
    } catch (e) {
      AppLogger.e('getPendingCheckOuts unexpected error', e);
      return _checkoutBox.query(
        CheckOutEntity_.propertyId.equals(propertyId) & CheckOutEntity_.checkoutStatus.equals('pending'),
      ).build().find();
    }
  }

  Future<Map<String, dynamic>> getCheckOutBilling(String checkinId) async {
    try {
      final response = await _dio.get('/checkout/billing/$checkinId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.e('getCheckOutBilling network failed', e);
      rethrow;
    } catch (e) {
      AppLogger.e('getCheckOutBilling unexpected error', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getTodaysCheckOuts(String propertyId) async {
    try {
      final response = await _dio.get('/checkout/today', queryParameters: {'property_id': propertyId});
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      AppLogger.w('getTodaysCheckOuts network failed, falling back to ObjectBox', e);
      return _checkoutBox.query(CheckOutEntity_.propertyId.equals(propertyId)).build().find();
    } catch (e) {
      AppLogger.e('getTodaysCheckOuts unexpected error', e);
      return _checkoutBox.query(CheckOutEntity_.propertyId.equals(propertyId)).build().find();
    }
  }

  Future<Map<String, dynamic>> getCheckOutDetail(String checkoutId) async {
    try {
      final response = await _dio.get('/checkout/$checkoutId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.e('getCheckOutDetail network failed', e);
      rethrow;
    } catch (e) {
      AppLogger.e('getCheckOutDetail unexpected error', e);
      rethrow;
    }
  }

  void _updateRoomToDirty(String roomId) {
    final query = _roomBox.query(RoomEntity_.uuid.equals(roomId)).build();
    final rooms = query.find();
    query.close();
    if (rooms.isNotEmpty) {
      final room = rooms.first;
      _roomBox.put(room);
    }
  }
}
