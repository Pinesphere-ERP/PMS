import '../../../features/checkout/domain/models/checkout_entity.dart';

abstract class ICheckoutDao {
  int put(CheckOutEntity entity);
  List<CheckOutEntity> getAll();
  CheckOutEntity? get(int id);
  bool remove(int id);
}
