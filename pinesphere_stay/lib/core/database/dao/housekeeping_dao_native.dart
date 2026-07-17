import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/housekeeping/domain/entities/housekeepingtaskentity.dart';
import 'housekeeping_dao.dart';

class HousekeepingDaoNative implements IHousekeepingDao {
  final Box<HousekeepingTaskEntity> _box;

  HousekeepingDaoNative(this._box);

  @override
  int put(HousekeepingTaskEntity entity) {
    return _box.put(entity);
  }

  @override
  List<HousekeepingTaskEntity> getAll() {
    return _box.getAll();
  }

  @override
  HousekeepingTaskEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
