import '../../../features/guests/domain/models/guest_entity.dart';
import 'guest_dao.dart';

class GuestDaoWeb implements IGuestDao {
  // Simple in-memory fallback for Web
  final Map<int, GuestEntity> _storage = {};
  int _counter = 1;

  @override
  int put(GuestEntity guest) {
    if (guest.id == 0) {
      guest.id = _counter++;
    }
    _storage[guest.id] = guest;
    return guest.id;
  }

  @override
  List<GuestEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  GuestEntity? get(int id) {
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
}
