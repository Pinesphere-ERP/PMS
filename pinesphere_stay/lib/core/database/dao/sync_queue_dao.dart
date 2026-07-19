import '../../../features/sync/domain/models/sync_queue_entity.dart';

abstract class ISyncQueueDao {
  /// Enqueue a mutation for sync
  int enqueue(SyncQueueEntity entity);

  /// Fetch pending items (status == 0) ordered by createdAt ascending
  List<SyncQueueEntity> getPending({int limit = 100});

  /// Fetch items by their specific status ordered by createdAt ascending
  List<SyncQueueEntity> getByStatus(int status, {int limit = 100});

  /// Get a specific sync item by ID
  SyncQueueEntity? get(int id);

  /// Mark an item as successfully synced
  bool markSuccess(int id);

  /// Mark an item as failed (status = 2)
  bool markFailure(int id);

  /// Delete items that have been successfully processed
  int removeProcessed();

  /// Delete specific processed items
  bool removeMany(List<int> ids);

  /// Reset failed items back to pending (status = 0)
  int retryFailed();
}
