import '../../../features/guests/domain/models/guest_entity.dart';

abstract class IGuestDao {
  int put(GuestEntity guest);
  List<GuestEntity> getAll();
  List<GuestEntity> findByProperty(String propertyId);
  GuestEntity? get(int id);
  bool remove(int id);
  GuestEntity? getByServerId(String serverId);
}
