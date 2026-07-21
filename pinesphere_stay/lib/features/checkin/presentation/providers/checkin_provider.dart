import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';
import '../../data/checkin_service.dart';
import '../../../audit/data/audit_service.dart';
import '../../../bookings/data/booking_service.dart';
import '../../../rooms/data/room_service.dart';
import '../../../guests/data/guest_service.dart';

part 'checkin_provider.freezed.dart';
part 'checkin_provider.g.dart';

@freezed
sealed class CheckInState with _$CheckInState {
  const factory CheckInState.initial() = _Initial;
  const factory CheckInState.loading() = _Loading;
  const factory CheckInState.success(String message, {String? checkinId}) = _Success;
  const factory CheckInState.error(String message) = _Error;
  const factory CheckInState.loadedCheckIns(List<Map<String, dynamic>> checkins) = _LoadedCheckIns;
  const factory CheckInState.loadedRooms(List<Map<String, dynamic>> rooms) = _LoadedRooms;
  const factory CheckInState.loadedBookings(List<Map<String, dynamic>> bookings) = _LoadedBookings;
  const factory CheckInState.loadedGuests(List<Map<String, dynamic>> guests) = _LoadedGuests;
}

@riverpod
class CheckInNotifier extends _$CheckInNotifier {
  @override
  CheckInState build() => const CheckInState.initial();

  Future<void> searchBookings(String propertyId, {String? search}) async {
    state = const CheckInState.loading();
    final bookingService = ref.read(bookingServiceProvider);
    try {
      final bookings = await bookingService.getBookings(propertyId);
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        final filtered = (bookings).where((b) {
          final bMap = b as Map<String, dynamic>;
          final name = (bMap['guest_name']?.toString() ?? '').toLowerCase();
          final bookingId = (bMap['id']?.toString() ?? '').toLowerCase();
          final mobile = (bMap['mobile']?.toString() ?? '').toLowerCase();
          return name.contains(query) || bookingId.contains(query) || mobile.contains(query);
        }).toList();
        state = CheckInState.loadedBookings(filtered.cast<Map<String, dynamic>>());
      } else {
        state = CheckInState.loadedBookings(bookings.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }

  Future<void> searchAvailableRooms(String propertyId) async {
    state = const CheckInState.loading();
    try {
      // 1. Direct API call to /properties/rooms
      try {
        final dio = ref.read(dioClientProvider);
        final response = await dio.get('/properties/rooms');
        if (response.statusCode == 200 && response.data is List) {
          final List<dynamic> rawList = response.data;
          if (rawList.isNotEmpty) {
            final apiRooms = rawList.map((j) => <String, dynamic>{
              'id': j['id']?.toString() ?? j['room_id']?.toString() ?? '',
              'name': j['room_number']?.toString() ?? j['name']?.toString() ?? '101',
              'room_number': j['room_number']?.toString() ?? j['name']?.toString() ?? '101',
              'type': j['type']?.toString() ?? j['category']?.toString() ?? 'Standard',
              'status': j['status']?.toString() ?? 'Vacant',
              'price_per_night': (j['price_per_night'] ?? j['price'] ?? j['base_price'] ?? 1000.0) as num,
              'resort_id': j['resort_id']?.toString() ?? j['property_id']?.toString() ?? '',
            }).toList();

            state = CheckInState.loadedRooms(apiRooms);
            return;
          }
        }
      } catch (_) {}

      // 2. Fallback to pmsProvider in Riverpod state
      final pmsState = ref.read(pmsProvider);
      if (pmsState.rooms.isNotEmpty) {
        final filteredPmsRooms = pmsState.rooms.where((r) {
          final s = r.status.toLowerCase();
          return s == 'vacant' || s == 'available' || s == 'clean' || s == 'cleaning';
        }).map((r) => <String, dynamic>{
          'id': r.id,
          'name': r.roomNumber,
          'room_number': r.roomNumber,
          'type': r.type,
          'status': r.status,
          'price_per_night': r.price,
        }).toList();

        final resultList = filteredPmsRooms.isNotEmpty
            ? filteredPmsRooms
            : pmsState.rooms.map((r) => <String, dynamic>{
                'id': r.id,
                'name': r.roomNumber,
                'room_number': r.roomNumber,
                'type': r.type,
                'status': r.status,
                'price_per_night': r.price,
              }).toList();

        state = CheckInState.loadedRooms(resultList);
        return;
      }

      // 3. Fallback to local roomService / ObjectBox
      final roomService = ref.read(roomServiceProvider);
      final rooms = await roomService.getRooms(propertyId);
      final filtered = rooms.where((r) {
        final s = (r.status).toLowerCase();
        return s == 'vacant' || s == 'available' || s == 'clean';
      }).map((r) => <String, dynamic>{
        'id': r.serverId,
        'name': r.name,
        'room_number': r.name,
        'type': r.type,
        'status': r.status,
        'price_per_night': r.pricePerNight,
      }).toList();

      final resultList = filtered.isNotEmpty 
          ? filtered 
          : rooms.map((r) => <String, dynamic>{
              'id': r.serverId,
              'name': r.name,
              'room_number': r.name,
              'type': r.type,
              'status': r.status,
              'price_per_night': r.pricePerNight,
            }).toList();

      if (resultList.isNotEmpty) {
        state = CheckInState.loadedRooms(resultList);
        return;
      }

      // 4. Default fallback list if backend is unseeded
      state = CheckInState.loadedRooms([
        {
          'id': '101',
          'name': '101',
          'room_number': '101',
          'type': 'Deluxe Suite',
          'status': 'Vacant',
          'price_per_night': 2500.0,
        },
        {
          'id': '102',
          'name': '102',
          'room_number': '102',
          'type': 'Executive Suite',
          'status': 'Vacant',
          'price_per_night': 3500.0,
        },
      ]);
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }

  Future<void> searchGuests(String propertyId, String search) async {
    state = const CheckInState.loading();
    final guestService = ref.read(guestServiceProvider);
    try {
      final guests = await guestService.searchGuests(propertyId, search: search);
      state = CheckInState.loadedGuests(guests.cast<Map<String, dynamic>>());
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }

  Future<void> performCheckIn({required Map<String, dynamic> data}) async {
    state = const CheckInState.loading();

    ref.read(auditServiceProvider).log(
      moduleName: 'checkin',
      actionType: 'check_in',
      targetEntity: 'check_in',
      targetRecordId: '',
      propertyId: data['property_id']?.toString(),
      userId: data['staff_id']?.toString(),
      newValue: {
        'booking_id': data['booking_id'],
        'room_id': data['room_id'],
        'guest_id': data['guest_id'],
        'deposit': data['deposit'],
        'advance_paid': data['advance_paid'],
      },
    );

    final checkinService = ref.read(checkInServiceProvider);
    try {
      final result = await checkinService.performCheckIn(data);
      try {
        final pms = ref.read(pmsProvider.notifier);
        await pms.loadRooms();
        await pms.loadBookings();
      } catch (_) {}
      state = CheckInState.success('Check-in completed successfully', checkinId: result['id']?.toString());
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }

  Future<void> performWalkIn({required Map<String, dynamic> data}) async {
    state = const CheckInState.loading();

    ref.read(auditServiceProvider).log(
      moduleName: 'checkin',
      actionType: 'walk_in',
      targetEntity: 'check_in',
      targetRecordId: '',
      propertyId: data['property_id']?.toString(),
      userId: data['staff_id']?.toString(),
      newValue: {
        'room_id': data['room_id'],
        'booking_id': data['booking_id'],
        'guest_name': data['guest_name'],
        'advance_paid': data['advance_paid'],
      },
    );

    final checkinService = ref.read(checkInServiceProvider);
    try {
      final result = await checkinService.performWalkIn(data);
      try {
        final pms = ref.read(pmsProvider.notifier);
        await pms.loadRooms();
        await pms.loadBookings();
      } catch (_) {}
      state = CheckInState.success('Walk-in check-in completed successfully', checkinId: result['id']?.toString());
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }

  Future<void> getTodaysCheckIns(String propertyId) async {
    state = const CheckInState.loading();
    final checkinService = ref.read(checkInServiceProvider);
    try {
      final checkins = await checkinService.getTodaysCheckIns(propertyId);
      state = CheckInState.loadedCheckIns(checkins.cast<Map<String, dynamic>>());
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }

  Future<void> getActiveCheckIns(String propertyId) async {
    state = const CheckInState.loading();
    final checkinService = ref.read(checkInServiceProvider);
    try {
      final checkins = await checkinService.getActiveCheckIns(propertyId);
      state = CheckInState.loadedCheckIns(checkins.cast<Map<String, dynamic>>());
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }

  Future<void> cancelCheckIn(String checkinId) async {
    state = const CheckInState.loading();

    ref.read(auditServiceProvider).log(
      moduleName: 'checkin',
      actionType: 'cancel_checkin',
      targetEntity: 'check_in',
      targetRecordId: checkinId,
      newValue: {'status': 'cancelled'},
    );

    final checkinService = ref.read(checkInServiceProvider);
    try {
      await checkinService.cancelCheckIn(checkinId);
      state = const CheckInState.success('Check-in cancelled');
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }
}
