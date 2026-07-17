import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/user_role_management/domain/entities/permissionentity.dart';
import 'perm_dao.dart';

class PermDaoNative implements IPermDao {
  final Box<PermissionEntity> _box;

  PermDaoNative(this._box);

  @override
  int put(PermissionEntity entity) {
    return _box.put(entity);
  }

  @override
  List<PermissionEntity> getAll() {
    return _box.getAll();
  }

  @override
  PermissionEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }

  @override
  PermissionEntity? getByPermissionCode(String code) {
    return _box.query(PermissionEntity_.permissionCode.equals(code)).build().findFirst();
  }
}
