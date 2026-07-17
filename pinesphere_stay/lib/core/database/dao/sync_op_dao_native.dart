import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/sync/domain/models/syncoperation.dart';
import 'sync_op_dao.dart';

class Sync_opDaoNative implements ISync_opDao {
  final Box<SyncOperation> _box;

  Sync_opDaoNative(this._box);

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
