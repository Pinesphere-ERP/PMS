import '../../../features/sync/domain/models/sync_queue_entity.dart';
import 'sync_queue_dao.dart';

class SyncQueueDaoWeb implements ISyncQueueDao {
  // In-memory list simulating a database box for web
  final List<SyncQueueEntity> _store = [];
  int _nextId = 1;

  @override
  int enqueue(SyncQueueEntity entity) {
    if (entity.id == 0) {
      entity.id = _nextId++;
    } else if (entity.id >= _nextId) {
      _nextId = entity.id + 1;
    }
    
    final existingIndex = _store.indexWhere((e) => e.id == entity.id);
    if (existingIndex != -1) {
      _store[existingIndex] = entity;
    } else {
      _store.add(entity);
    }
    return entity.id;
  }

  @override
  List<SyncQueueEntity> getPending({int limit = 100}) {
    // 0 = Pending
    final results = _store.where((e) => e.status == 0).toList();
    results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return results.take(limit).toList();
  }

  @override
  List<SyncQueueEntity> getByStatus(int status, {int limit = 100}) {
    final results = _store.where((e) => e.status == status).toList();
    results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return results.take(limit).toList();
  }

  @override
  SyncQueueEntity? get(int id) {
    try {
      return _store.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  bool markSuccess(int id) {
    final entity = get(id);
    if (entity != null) {
      entity.status = 3; // 3 = Success/Processed
      enqueue(entity);
      return true;
    }
    return false;
  }

  @override
  bool markFailure(int id) {
    final entity = get(id);
    if (entity != null) {
      entity.status = 2; // 2 = Failed
      enqueue(entity);
      return true;
    }
    return false;
  }

  @override
  int removeProcessed() {
    final initialLength = _store.length;
    _store.removeWhere((e) => e.status == 3);
    return initialLength - _store.length;
  }

  @override
  bool removeMany(List<int> ids) {
    _store.removeWhere((e) => ids.contains(e.id));
    return true;
  }

  @override
  int retryFailed() {
    int count = 0;
    for (var item in _store) {
      if (item.status == 2) {
        item.status = 0;
        count++;
      }
    }
    return count;
  }
}
