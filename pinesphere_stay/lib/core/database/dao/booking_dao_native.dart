import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/bookings/domain/models/booking_entity.dart';
import 'booking_dao.dart';

class BookingDaoNative implements IBookingDao {
  final Box<BookingEntity> _box;

  BookingDaoNative(this._box);

  @override
  int put(BookingEntity booking) {
    return _box.put(booking);
  }

  @override
  List<BookingEntity> getAll() {
    return _box.getAll();
  }

  @override
  BookingEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
