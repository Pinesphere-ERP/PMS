import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../core/sync/queue/sync_operation.dart';
import 'sync_op_dao.dart';

class SyncOpDaoNative implements ISyncOpDao {
  final Box<SyncOperation> _box;

  SyncOpDaoNative(this._box);

  @override
  int put(SyncOperation entity) {
    return _box.put(entity);
  }

  @override
  List<SyncOperation> getAll() {
    return _box.getAll();
  }

  @override
  SyncOperation? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
