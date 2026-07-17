import '../../../features/sync/domain/models/syncqueueentity.dart';
import 'sync_dao.dart';

class SyncDaoWeb implements ISyncDao {
  final Map<int, SyncQueueEntity> _storage = {};
  int _counter = 1;

  @override
  int put(SyncQueueEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<SyncQueueEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  SyncQueueEntity? get(int id) {
    return _storage[id];
  }

  @override
  bool remove(int id) {
    if (_storage.containsKey(id)) {
      _storage.remove(id);
      return true;
    }
    return false;
  }
}
