import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/checkin_service.dart';
import '../../../audit/data/audit_service.dart';


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
  String? _lastSearchQuery;
  String? _lastPropertyId;

  @override
  CheckInState build() {
    ref.listen(pmsProvider, (previous, next) {
      final shouldUpdate = state.maybeWhen(
        initial: () => true,
        loadedBookings: (_) => true,
        orElse: () => false,
      );
      if (shouldUpdate && _lastPropertyId != null) {
        _updateBookingsFromState(next);
      }
    });
    return const CheckInState.initial();
  }

  void _updateBookingsFromState(PmsState pmsState) {
    final eligibleBookings = pmsState.bookings.where((b) => b.status == 'Upcoming').toList();

    if (_lastSearchQuery != null && _lastSearchQuery!.isNotEmpty) {
      final query = _lastSearchQuery!.toLowerCase();
      final filtered = eligibleBookings.where((b) {
        final name = b.guestName.toLowerCase();
        final bookingId = b.id.toLowerCase();
        final mobile = b.guestPhone.toLowerCase();
        return name.contains(query) || bookingId.contains(query) || mobile.contains(query);
      }).toList();
      state = CheckInState.loadedBookings(filtered.map((e) => _mapBookingModel(e)).toList());
    } else {
      state = CheckInState.loadedBookings(eligibleBookings.map((e) => _mapBookingModel(e)).toList());
    }
  }

  Future<void> searchBookings(String propertyId, {String? search}) async {
    _lastPropertyId = propertyId;
    _lastSearchQuery = search;
    
    final pmsState = ref.read(pmsProvider);
    _updateBookingsFromState(pmsState);
  }

  Map<String, dynamic> _mapBookingModel(BookingModel b) {
    return {
      'id': b.id,
      'booking_id': b.id,
      'guest_name': b.guestName,
      'guest_phone': b.guestPhone,
      'guest_email': b.guestEmail,
      'room_id': b.roomId,
      'room_number': b.roomNumber,
      'check_in_date': b.checkInDate.toIso8601String(),
      'check_out_date': b.checkOutDate.toIso8601String(),
      'booking_status': b.status,
      'deposit': b.depositPaid,
      'advance_paid': b.depositPaid,
      'total_payable': b.totalSum,
      'pending_amount': b.totalSum - b.depositPaid,
    };
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
