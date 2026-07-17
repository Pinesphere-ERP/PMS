import '../../../features/checkout/domain/entities/checkoutentity.dart';

abstract class ICheckoutDao {
  int put(CheckOutEntity entity);
  List<CheckOutEntity> getAll();
  CheckOutEntity? get(int id);
  bool remove(int id);
}
