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
}
