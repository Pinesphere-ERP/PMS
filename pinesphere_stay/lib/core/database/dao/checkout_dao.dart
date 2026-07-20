import '../../../features/checkout/domain/models/checkout_entity.dart';

abstract class ICheckoutDao {
  int put(CheckOutEntity entity);
  List<CheckOutEntity> getAll();
  CheckOutEntity? get(int id);
  bool remove(int id);
  void putMany(List<CheckOutEntity> checkouts);
  List<CheckOutEntity> findByProperty(String propertyId);
  List<CheckOutEntity> findPendingByProperty(String propertyId);
  CheckOutEntity? getByServerId(String serverId);
}
