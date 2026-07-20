import '../../../features/checkin/domain/models/checkin_entity.dart';
import 'checkin_dao.dart';

class CheckinDaoWeb implements ICheckinDao {
  final Map<int, CheckInEntity> _storage = {};
  int _counter = 1;

  @override
  int put(CheckInEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<CheckInEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  CheckInEntity? get(int id) {
    return _storage[id];
  }

  @override
  bool remove(int id) {
    if (_storage.containsKey(id)) {
      _storage.remove(id);
      return true;
    }
    return false;
  }

  @override
  void putMany(List<CheckInEntity> checkins) {
    for (final checkin in checkins) {
      put(checkin);
    }
  }

  @override
  List<CheckInEntity> findByProperty(String propertyId) {
    return _storage.values.where((c) => c.propertyId == propertyId).toList();
  }

  @override
  List<CheckInEntity> findActiveByProperty(String propertyId) {
    return _storage.values.where((c) => c.propertyId == propertyId && c.status == 'active').toList();
  }
  @override
  CheckInEntity? findByUuid(String uuid) {
    try {
      return getAll().firstWhere((e) => e.uuid == uuid);
    } catch (_) {
      return null;
    }
  }

}
