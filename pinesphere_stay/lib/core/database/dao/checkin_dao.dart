import '../../../features/checkin/domain/entities/checkinentity.dart';

abstract class ICheckinDao {
  int put(CheckInEntity entity);
  List<CheckInEntity> getAll();
  CheckInEntity? get(int id);
  bool remove(int id);
}
