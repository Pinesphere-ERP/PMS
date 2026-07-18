import '../../../features/sync/domain/models/sync_queue_entity.dart';

abstract class ISyncDao {
  int put(SyncQueueEntity entity);
  List<SyncQueueEntity> getAll();
  SyncQueueEntity? get(int id);
  bool remove(int id);
}
