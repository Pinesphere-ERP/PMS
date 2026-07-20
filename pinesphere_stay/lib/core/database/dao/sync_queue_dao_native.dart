import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/sync/domain/models/sync_queue_entity.dart';
import 'sync_queue_dao.dart';

class SyncQueueDaoNative implements ISyncQueueDao {
  final Box<SyncQueueEntity> _box;

  SyncQueueDaoNative(this._box);

  @override
  int enqueue(SyncQueueEntity entity) {
    return _box.put(entity);
  }

  @override
  List<SyncQueueEntity> getPending({int limit = 100}) {
    // 0 = Pending
    final query = _box
        .query(SyncQueueEntity_.status.equals(0))
        .order(SyncQueueEntity_.createdAt)
        .build();
    query.limit = limit;
    final results = query.find();
    query.close();
    return results;
  }

  @override
  List<SyncQueueEntity> getByStatus(int status, {int limit = 100}) {
    final query = _box
        .query(SyncQueueEntity_.status.equals(status))
        .order(SyncQueueEntity_.createdAt)
        .build();
    query.limit = limit;
    final results = query.find();
    query.close();
    return results;
  }

  @override
  SyncQueueEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool markSuccess(int id) {
    final entity = get(id);
    if (entity != null) {
      entity.status = 3; // 3 = Success/Processed
      _box.put(entity);
      return true;
    }
    return false;
  }

  @override
  bool markFailure(int id) {
    final entity = get(id);
    if (entity != null) {
      entity.status = 2; // 2 = Failed
      _box.put(entity);
      return true;
    }
    return false;
  }

  @override
  int removeProcessed() {
    // Note: If using markSuccess -> status 3, we delete status 3.
    // If just using removeMany, this could be a fallback.
    final query = _box.query(SyncQueueEntity_.status.equals(3)).build();
    final count = query.remove();
    query.close();
    return count;
  }

  @override
  bool removeMany(List<int> ids) {
    _box.removeMany(ids);
    return true;
  }

  @override
  int retryFailed() {
    // Find all failed items (status = 2) and mark them as pending (status = 0)
    final query = _box.query(SyncQueueEntity_.status.equals(2)).build();
    final failedItems = query.find();
    query.close();
    
    if (failedItems.isEmpty) return 0;
    
    for (var item in failedItems) {
      item.status = 0;
    }
    _box.putMany(failedItems);
    return failedItems.length;
  }
}
