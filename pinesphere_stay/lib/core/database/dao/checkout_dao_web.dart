import '../../../features/checkout/domain/entities/checkoutentity.dart';
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
}
