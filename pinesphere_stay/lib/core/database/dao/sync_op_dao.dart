import '../../../core/sync/queue/sync_operation.dart';

abstract class ISync_opDao {
  int put(SyncOperation entity);
  List<SyncOperation> getAll();
  SyncOperation? get(int id);
  bool remove(int id);
}
