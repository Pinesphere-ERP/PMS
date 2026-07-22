import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/checkin_service.dart';
import '../../../audit/data/audit_service.dart';
import '../../../bookings/data/booking_service.dart';

import '../../../guests/data/guest_service.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';
import 'package:pinesphere_stay/core/network/error_formatter.dart';

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
      final allBookings = await bookingService.getBookings(propertyId);
      final eligibleBookings = allBookings.where((b) {
        final status = (b as Map<String, dynamic>)['booking_status']?.toString().toLowerCase() ?? '';
        return status == 'upcoming' || status == 'confirmed';
      }).toList();

      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        final filtered = eligibleBookings.where((b) {
          final bMap = b as Map<String, dynamic>;
          final name = (bMap['guest_name']?.toString() ?? '').toLowerCase();
          final bookingId = (bMap['id']?.toString() ?? '').toLowerCase();
          final mobile = (bMap['mobile']?.toString() ?? '').toLowerCase();
          return name.contains(query) || bookingId.contains(query) || mobile.contains(query);
        }).toList();
        state = CheckInState.loadedBookings(filtered.cast<Map<String, dynamic>>());
      } else {
        state = CheckInState.loadedBookings(eligibleBookings.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      state = CheckInState.error(formatError(e));
    }
  }

  Future<void> searchAvailableRooms(String propertyId) async {
    state = const CheckInState.loading();
    try {
      final pmsState = ref.read(pmsProvider);
      final vacantRooms = pmsState.rooms
          .where((r) => r.status.toLowerCase() == 'vacant')
          .map((r) => <String, dynamic>{
        'id': r.id,
        'name': r.roomNumber,
        'type': r.type,
        'status': r.status,
        'price_per_night': r.price,
      }).toList();
      
      state = CheckInState.loadedRooms(vacantRooms);
    } catch (e) {
      state = CheckInState.error(formatError(e));
    }
  }

  Future<void> searchGuests(String propertyId, String search) async {
    state = const CheckInState.loading();
    final guestService = ref.read(guestServiceProvider);
    try {
      final guests = await guestService.searchGuests(propertyId, search: search);
      state = CheckInState.loadedGuests(guests.cast<Map<String, dynamic>>());
    } catch (e) {
      state = CheckInState.error(formatError(e));
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
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(pmsProvider);
      state = CheckInState.success('Check-in completed successfully', checkinId: result['id']?.toString());
    } catch (e) {
      state = CheckInState.error(formatError(e));
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
      state = CheckInState.success('Walk-in check-in completed successfully', checkinId: result['id']?.toString());
    } catch (e) {
      state = CheckInState.error(formatError(e));
    }
  }

  Future<void> getTodaysCheckIns(String propertyId) async {
    state = const CheckInState.loading();
    final checkinService = ref.read(checkInServiceProvider);
    try {
      final checkins = await checkinService.getTodaysCheckIns(propertyId);
      state = CheckInState.loadedCheckIns(checkins.cast<Map<String, dynamic>>());
    } catch (e) {
      state = CheckInState.error(formatError(e));
    }
  }

  Future<void> getActiveCheckIns(String propertyId) async {
    state = const CheckInState.loading();
    final checkinService = ref.read(checkInServiceProvider);
    try {
      final checkins = await checkinService.getActiveCheckIns(propertyId);
      state = CheckInState.loadedCheckIns(checkins.cast<Map<String, dynamic>>());
    } catch (e) {
      state = CheckInState.error(formatError(e));
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
      state = CheckInState.error(formatError(e));
    }
  }
}
