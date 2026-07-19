import '../../../features/guests/domain/models/guest_entity.dart';

abstract class IGuestDao {
  int put(GuestEntity guest);
  List<GuestEntity> getAll();
  GuestEntity? get(int id);
  bool remove(int id);
  GuestEntity? findByUuid(String uuid);
}
