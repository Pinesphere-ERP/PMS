import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/checkin/domain/entities/checkinentity.dart';
import 'checkin_dao.dart';

class CheckinDaoNative implements ICheckinDao {
  final Box<CheckInEntity> _box;

  CheckinDaoNative(this._box);

  @override
  int put(CheckInEntity entity) {
    return _box.put(entity);
  }

  @override
  List<CheckInEntity> getAll() {
    return _box.getAll();
  }

  @override
  CheckInEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
