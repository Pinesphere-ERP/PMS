import '../../../features/user_role_management/domain/entities.dart';
import 'role_perm_dao.dart';

class RolePermDaoWeb implements IRolePermDao {
  final Map<int, RolePermissionEntity> _storage = {};
  int _counter = 1;

  @override
  int put(RolePermissionEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<RolePermissionEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  RolePermissionEntity? get(int id) {
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
  List<RolePermissionEntity> getByRoleId(String roleId) {
    return _storage.values.where((e) => e.roleId == roleId).toList();
  }

  @override
  RolePermissionEntity? getByServerId(String serverId) {
    return _storage.values.firstWhere((e) => e.serverId == serverId, orElse: () => null as dynamic);
  }
}
