import '../../../features/user_role_management/domain/entities.dart';

abstract class IRolePermDao {
  int put(RolePermissionEntity entity);
  List<RolePermissionEntity> getAll();
  RolePermissionEntity? get(int id);
  bool remove(int id);
  List<RolePermissionEntity> getByRoleId(String roleId);
}
