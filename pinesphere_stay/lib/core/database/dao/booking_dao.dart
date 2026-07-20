import '../../../features/bookings/domain/models/booking_entity.dart';

abstract class IBookingDao {
  int put(BookingEntity booking);
  void putMany(List<BookingEntity> bookings);
  List<BookingEntity> getAll();
  List<BookingEntity> findByProperty(String propertyId);
  BookingEntity? get(int id);
  bool remove(int id);
  BookingEntity? getByServerId(String serverId);
}
