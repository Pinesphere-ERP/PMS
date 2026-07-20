import 'dart:async';
import '../../../features/user_role_management/domain/entities.dart';
import 'role_dao.dart';

class RoleDaoWeb implements IRoleDao {
  final Map<int, RoleEntity> _storage = {};
  int _counter = 1;
  final StreamController<List<RoleEntity>> _controller = StreamController.broadcast();

  @override
  int put(RoleEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    _controller.add(getAll());
    return entity.id;
  }

  @override
  void putMany(List<RoleEntity> roles) {
    for (var r in roles) {
      put(r);
    }
  }

  @override
  List<RoleEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  Stream<List<RoleEntity>> watchAll() {
    return _controller.stream;
  }

  @override
  RoleEntity? get(int id) {
    return _storage[id];
  }

  @override
  bool remove(int id) {
    final removed = _storage.remove(id) != null;
    if (removed) _controller.add(getAll());
    return removed;
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
