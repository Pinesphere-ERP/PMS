import '../../../features/user_role_management/domain/entities.dart';
import 'role_dao.dart';

class RoleDaoWeb implements IRoleDao {
  final Map<int, RoleEntity> _storage = {};
  int _counter = 1;

  @override
  int put(RoleEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  void putMany(List<RoleEntity> roles) {
    for (var role in roles) {
      put(role);
    }
  }

  @override
  List<RoleEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  Stream<List<RoleEntity>> watchAll() {
    return Stream.value(_storage.values.toList());
  }

  @override
  RoleEntity? get(int id) {
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
  RoleEntity? getByServerId(String serverId) {
    try {
      return _storage.values.firstWhere((e) => e.serverId == serverId);
    } catch (_) {
      return null;
    }
  }
}
