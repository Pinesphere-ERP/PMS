import '../../../features/user_role_management/domain/entities.dart';
import 'perm_dao.dart';

class PermDaoWeb implements IPermDao {
  final Map<int, PermissionEntity> _storage = {};
  int _counter = 1;

  @override
  int put(PermissionEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<PermissionEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  PermissionEntity? get(int id) {
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
  PermissionEntity? getByPermissionCode(String code) {
    try {
      return _storage.values.firstWhere((e) => e.permissionCode == code);
    } catch (_) {
      return null;
    }
  }

  @override
  PermissionEntity? getByServerId(String serverId) {
    try {
      return _storage.values.firstWhere((e) => e.serverId == serverId);
    } catch (_) {
      return null;
    }
  }
}
