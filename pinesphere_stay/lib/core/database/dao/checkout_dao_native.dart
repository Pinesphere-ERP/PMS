import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/checkout/domain/models/checkout_entity.dart';
import 'checkout_dao.dart';

class CheckoutDaoNative implements ICheckoutDao {
  final Box<CheckOutEntity> _box;

  CheckoutDaoNative(this._box);

  @override
  int put(CheckOutEntity entity) {
    return _box.put(entity);
  }

  @override
  List<CheckOutEntity> getAll() {
    return _box.getAll();
  }

  @override
  CheckOutEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }

  @override
  void putMany(List<CheckOutEntity> checkouts) {
    _box.putMany(checkouts);
  }

  @override
  List<CheckOutEntity> findByProperty(String propertyId) {
    final query = _box.query(CheckOutEntity_.propertyId.equals(propertyId)).build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  List<CheckOutEntity> findPendingByProperty(String propertyId) {
    final query = _box.query(
      CheckOutEntity_.propertyId.equals(propertyId).and(CheckOutEntity_.checkoutStatus.equals('pending')),
    ).build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }
}
