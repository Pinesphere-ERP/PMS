import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../main.dart';
import '../../../user_role_management/domain/entities.dart';

part 'user_provider.g.dart';

@riverpod
Stream<List<UserEntity>> userList(Ref ref) {
  final userDao = databaseService.userDao;
  return userDao.watchAll().map((users) => 
    users.where((u) => !u.isDeleted).toList()
  );
}
