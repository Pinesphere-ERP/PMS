import '../../../features/checkout/domain/models/checkout_entity.dart';
import 'checkout_dao.dart';

class CheckoutDaoWeb implements ICheckoutDao {
  final Map<int, CheckOutEntity> _storage = {};
  int _counter = 1;

  @override
  int put(CheckOutEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<CheckOutEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  CheckOutEntity? get(int id) {
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
  void putMany(List<CheckOutEntity> checkouts) {
    for (final checkout in checkouts) {
      put(checkout);
    }
  }

  @override
  List<CheckOutEntity> findByProperty(String propertyId) {
    return _storage.values.where((c) => c.propertyId == propertyId).toList();
  }

  @override
  List<CheckOutEntity> findPendingByProperty(String propertyId) {
    return _storage.values.where((c) => c.propertyId == propertyId && c.checkoutStatus == 'pending').toList();
  }
  @override
  CheckOutEntity? findByUuid(String uuid) {
    try {
      return getAll().firstWhere((e) => e.uuid == uuid);
    } catch (_) {
      return null;
    }
  }

}
