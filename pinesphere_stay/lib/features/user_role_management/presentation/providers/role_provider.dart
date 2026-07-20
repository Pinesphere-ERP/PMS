import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../main.dart';
import '../../../user_role_management/domain/entities.dart';

part 'role_provider.g.dart';

@riverpod
Stream<List<RoleEntity>> roleList(Ref ref) {
  final roleDao = databaseService.roleDao;
  return roleDao.watchAll().map((roles) => 
    roles.where((r) => !r.isDeleted).toList()
  );
}
