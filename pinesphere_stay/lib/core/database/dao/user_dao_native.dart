import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/user_role_management/domain/entities.dart';
import 'user_dao.dart';

class UserDaoNative implements IUserDao {
  final Box<UserEntity> _box;

  UserDaoNative(this._box);

  @override
  int put(UserEntity entity) {
    return _box.put(entity);
  }

  @override
  List<UserEntity> getAll() {
    return _box.getAll();
  }

  @override
  Stream<List<UserEntity>> watchAll() {
    return _box.query().watch(triggerImmediately: true).map((query) => query.find());
  }

  @override
  UserEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }

  @override
  UserEntity? getByServerId(String serverId) {
    return _box.query(UserEntity_.serverId.equals(serverId)).build().findFirst();
  }

  @override
  UserEntity? getByEmail(String email) {
    return _box.query(UserEntity_.email.equals(email)).build().findFirst();
  }
}
