import 'dart:async';
import '../../../features/reports/domain/models/kpi_snapshot_entity.dart';
import 'kpi_dao.dart';

class KpiDaoWeb implements IKpiDao {
  final Map<int, KpiSnapshotEntity> _storage = {};
  int _counter = 1;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  int put(KpiSnapshotEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    _changes.add(null);
    return entity.id;
  }

  @override
  List<KpiSnapshotEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  KpiSnapshotEntity? get(int id) {
    return _storage[id];
  }

  @override
  bool remove(int id) {
    if (_storage.containsKey(id)) {
      _storage.remove(id);
      _changes.add(null);
      return true;
    }
    return false;
  }

  @override
  KpiSnapshotEntity? findByPropertyAndDate(String propertyId, String dateKey) {
    try {
      return _storage.values.firstWhere((e) => e.propertyId == propertyId && e.snapshotDate == dateKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<KpiSnapshotEntity?> watchByPropertyAndDate(String propertyId, String dateKey) async* {
    yield findByPropertyAndDate(propertyId, dateKey);
    await for (final _ in _changes.stream) {
      yield findByPropertyAndDate(propertyId, dateKey);
    }
  }

  @override
  List<KpiSnapshotEntity> getRange(String propertyId, String startKey, String endKey) {
    final list = _storage.values.where((e) {
      return e.propertyId == propertyId && e.snapshotDate.compareTo(startKey) >= 0 && e.snapshotDate.compareTo(endKey) <= 0;
    }).toList();
    list.sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));
    return list;
  }
}
