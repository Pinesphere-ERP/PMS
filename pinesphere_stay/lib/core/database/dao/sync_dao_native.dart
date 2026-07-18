import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/sync/domain/models/syncqueueentity.dart';
import 'sync_dao.dart';

class SyncDaoNative implements ISyncDao {
  final Box<SyncQueueEntity> _box;

  SyncDaoNative(this._box);

  @override
  int put(SyncQueueEntity entity) {
    return _box.put(entity);
  }

  @override
  List<SyncQueueEntity> getAll() {
    return _box.getAll();
  }

  @override
  SyncQueueEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
