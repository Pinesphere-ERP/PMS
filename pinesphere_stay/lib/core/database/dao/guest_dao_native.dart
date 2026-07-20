import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/guests/domain/models/guest_entity.dart';
import 'guest_dao.dart';

class GuestDaoNative implements IGuestDao {
  final Box<GuestEntity> _box;

  GuestDaoNative(this._box);

  @override
  int put(GuestEntity guest) {
    return _box.put(guest);
  }

  @override
  List<GuestEntity> getAll() {
    return _box.getAll();
  }

  @override
  List<GuestEntity> findByProperty(String propertyId) {
    final query = _box.query(GuestEntity_.propertyId.equals(propertyId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  @override
  GuestEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
  @override
  GuestEntity? getByServerId(String serverId) {
    final query = _box.query(GuestEntity_.serverId.equals(serverId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

}
