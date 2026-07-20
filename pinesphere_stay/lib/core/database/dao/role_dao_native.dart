import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/user_role_management/domain/entities.dart';
import 'role_dao.dart';

class RoleDaoNative implements IRoleDao {
  final Box<RoleEntity> _box;

  RoleDaoNative(this._box);

  @override
  int put(RoleEntity entity) {
    return _box.put(entity);
  }

  @override
  void putMany(List<RoleEntity> roles) {
    _box.putMany(roles);
  }

  @override
  List<RoleEntity> getAll() {
    return _box.getAll();
  }

  @override
  Stream<List<RoleEntity>> watchAll() {
    return _box.query().watch(triggerImmediately: true).map((query) => query.find());
  }

  @override
  RoleEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }

  @override
  RoleEntity? getByServerId(String serverId) {
    final query = _box.query(RoleEntity_.serverId.equals(serverId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  @override
  Stream<List<RoleEntity>> watchAll() {
    return _box.query().watch(triggerImmediately: true).map((query) => query.find());
  }
}
