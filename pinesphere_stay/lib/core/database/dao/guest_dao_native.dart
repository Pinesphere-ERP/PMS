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
  GuestEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
