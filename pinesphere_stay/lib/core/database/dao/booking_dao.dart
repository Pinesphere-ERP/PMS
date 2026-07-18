import '../../../features/bookings/domain/models/booking_entity.dart';

abstract class IBookingDao {
  int put(BookingEntity booking);
  List<BookingEntity> getAll();
  BookingEntity? get(int id);
  bool remove(int id);
}
