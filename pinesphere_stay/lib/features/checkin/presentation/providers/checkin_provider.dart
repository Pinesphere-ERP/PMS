import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/checkin_service.dart';
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
      final bookings = await bookingService.getBookings(propertyId, status: 'confirmed');
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
    final roomService = ref.read(roomServiceProvider);
    try {
      final rooms = await roomService.getRooms(propertyId);
      final vacantRooms = rooms.where((r) => r.status == 'Vacant').map((r) => <String, dynamic>{
        'id': r.uuid,
        'name': r.name,
        'type': r.type,
        'status': r.status,
        'price_per_night': r.pricePerNight,
      }).toList();
      state = CheckInState.loadedRooms(vacantRooms);
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
    final checkinService = ref.read(checkInServiceProvider);
    try {
      final result = await checkinService.performCheckIn(data);
      state = CheckInState.success('Check-in completed successfully', checkinId: result['id']?.toString());
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }

  Future<void> performWalkIn({required Map<String, dynamic> data}) async {
    state = const CheckInState.loading();
    final checkinService = ref.read(checkInServiceProvider);
    try {
      final result = await checkinService.performWalkIn(data);
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
    final checkinService = ref.read(checkInServiceProvider);
    try {
      await checkinService.cancelCheckIn(checkinId);
      state = const CheckInState.success('Check-in cancelled');
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }
}
