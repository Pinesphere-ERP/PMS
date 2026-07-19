import '../../../features/bookings/domain/models/booking_entity.dart';
import 'booking_dao.dart';

class BookingDaoWeb implements IBookingDao {
  final Map<int, BookingEntity> _storage = {};
  int _counter = 1;

  @override
  int put(BookingEntity booking) {
    if (booking.id == 0) {
      booking.id = _counter++;
    }
    _storage[booking.id] = booking;
    return booking.id;
  }

  @override
  List<BookingEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  BookingEntity? get(int id) {
    return _storage[id];
  }

  @override
  bool remove(int id) {
    if (_storage.containsKey(id)) {
      _storage.remove(id);
      return true;
    }
    return false;
  }

  @override
  void putMany(List<BookingEntity> bookings) {
    for (var booking in bookings) {
      put(booking);
    }
  }
  @override
  BookingEntity? findByUuid(String uuid) {
    try {
      return getAll().firstWhere((e) => e.uuid == uuid);
    } catch (_) {
      return null;
    }
  }

}
