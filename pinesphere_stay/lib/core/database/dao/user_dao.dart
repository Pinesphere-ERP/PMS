import '../../../features/user_role_management/domain/entities.dart';

abstract class IUserDao {
  int put(UserEntity entity);
  List<UserEntity> getAll();
  UserEntity? get(int id);
  bool remove(int id);
  UserEntity? getByServerId(String serverId);
  UserEntity? getByEmail(String email);
}
