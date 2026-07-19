import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/checkin/domain/models/checkin_entity.dart';
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

  @override
  void putMany(List<CheckInEntity> checkins) {
    _box.putMany(checkins);
  }

  @override
  List<CheckInEntity> findByProperty(String propertyId) {
    final query = _box.query(CheckInEntity_.propertyId.equals(propertyId)).build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  List<CheckInEntity> findActiveByProperty(String propertyId) {
    final query = _box.query(
      CheckInEntity_.propertyId.equals(propertyId) & CheckInEntity_.status.equals('active'),
    ).build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }
}
