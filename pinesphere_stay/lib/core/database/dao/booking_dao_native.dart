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
  List<BookingEntity> findByProperty(String propertyId) {
    final query = _box.query(BookingEntity_.propertyId.equals(propertyId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  @override
  BookingEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }

  @override
  void putMany(List<BookingEntity> bookings) {
    _box.putMany(bookings);
  }
  @override
  BookingEntity? getByServerId(String serverId) {
    final query = _box.query(BookingEntity_.serverId.equals(serverId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

}
