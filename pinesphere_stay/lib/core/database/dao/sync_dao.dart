import '../../../features/sync/domain/models/syncqueueentity.dart';

abstract class ISyncDao {
  int put(SyncQueueEntity entity);
  List<SyncQueueEntity> getAll();
  SyncQueueEntity? get(int id);
  bool remove(int id);
}
