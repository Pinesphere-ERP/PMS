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
    // 'Pending'
    final query = _box
        .query(SyncQueueEntity_.status.equals('Pending'))
        .order(SyncQueueEntity_.createdAt)
        .build();
    query.limit = limit;
    final results = query.find();
    query.close();
    return results;
  }

  @override
  List<SyncQueueEntity> getByStatus(String status, {int limit = 100}) {
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
      entity.status = 'Synced';
      _box.put(entity);
      return true;
    }
    return false;
  }

  @override
  bool markFailure(int id) {
    final entity = get(id);
    if (entity != null) {
      entity.status = 'Failed';
      _box.put(entity);
      return true;
    }
    return false;
  }

  @override
  int removeProcessed() {
    // Note: If using markSuccess -> status 'Synced', we delete status 'Synced'.
    // If just using removeMany, this could be a fallback.
    final query = _box.query(SyncQueueEntity_.status.equals('Synced')).build();
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
    // Find all failed items (status = 'Failed') and mark them as pending (status = 'Pending')
    final query = _box.query(SyncQueueEntity_.status.equals('Failed')).build();
    final failedItems = query.find();
    query.close();
    
    if (failedItems.isEmpty) return 0;
    
    for (var item in failedItems) {
      item.status = 'Pending';
    }
    _box.putMany(failedItems);
    return failedItems.length;
  }
}
