import '../../../features/sync/domain/models/syncoperation.dart';
import 'sync_op_dao.dart';

class Sync_opDaoWeb implements ISync_opDao {
  final Map<int, SyncOperation> _storage = {};
  int _counter = 1;

  @override
  int put(SyncOperation entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<SyncOperation> getAll() {
    return _storage.values.toList();
  }

  @override
  SyncOperation? get(int id) {
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
