import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/user_role_management/domain/entities.dart';
import 'role_perm_dao.dart';

class RolePermDaoNative implements IRolePermDao {
  final Box<RolePermissionEntity> _box;

  RolePermDaoNative(this._box);

  @override
  int put(RolePermissionEntity entity) {
    return _box.put(entity);
  }

  @override
  List<RolePermissionEntity> getAll() {
    return _box.getAll();
  }

  @override
  RolePermissionEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }

  @override
  List<RolePermissionEntity> getByRoleId(String roleId) {
    return _box.query(RolePermissionEntity_.roleId.equals(roleId)).build().find();
  }

  @override
  RolePermissionEntity? getByServerId(String serverId) {
    return _box.query(RolePermissionEntity_.serverId.equals(serverId)).build().findFirst();
  }
}
