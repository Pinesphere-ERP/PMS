import '../../../features/user_role_management/domain/entities.dart';

abstract class IPermDao {
  int put(PermissionEntity entity);
  List<PermissionEntity> getAll();
  PermissionEntity? get(int id);
  bool remove(int id);
  PermissionEntity? getByPermissionCode(String code);
}
