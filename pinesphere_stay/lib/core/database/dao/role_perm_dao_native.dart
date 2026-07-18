import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/user_role_management/domain/entities.dart';
import 'role_perm_dao.dart';

class Role_permDaoNative implements IRole_permDao {
  final Box<RolePermissionEntity> _box;

  Role_permDaoNative(this._box);

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
}
