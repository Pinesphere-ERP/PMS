import '../../../features/user_role_management/domain/entities.dart';
import 'user_dao.dart';

class UserDaoWeb implements IUserDao {
  final Map<int, UserEntity> _storage = {};
  int _counter = 1;

  @override
  int put(UserEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<UserEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  UserEntity? get(int id) {
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
  UserEntity? getByServerId(String serverId) {
    try {
      return _storage.values.firstWhere((e) => e.serverId == serverId);
    } catch (_) {
      return null;
    }
  }
}
