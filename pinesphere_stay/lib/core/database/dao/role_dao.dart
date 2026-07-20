import '../../../features/user_role_management/domain/entities.dart';

abstract class IRoleDao {
  int put(RoleEntity entity);
  void putMany(List<RoleEntity> roles);
  List<RoleEntity> getAll();
  RoleEntity? get(int id);
  bool remove(int id);
  RoleEntity? getByServerId(String serverId);
}
