import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/housekeeping_room_service.dart';
import '../../domain/models/housekeeping_room_status_model.dart';
import '../../../../main.dart'; // for databaseService

final housekeeperRoomsProvider = FutureProvider.autoDispose<List<HousekeepingRoomStatusModel>>((ref) async {
  final service = ref.watch(housekeepingRoomServiceProvider);
  final authState = ref.watch(authProvider);
  
  final propertyId = authState.maybeWhen(
    authenticated: (user) => user.propertyId,
    orElse: () => null,
  );

  if (propertyId == null) return [];

  try {
    return await service.getRooms();
  } catch (e) {
    // Fallback to local DB
    final dao = databaseService.housekeepingRoomStatusDao;
    final entities = dao.getByPropertyId(propertyId);
    return entities.map((e) => HousekeepingRoomStatusModel(
      id: e.serverId,
      propertyId: e.propertyId,
      roomId: e.roomId,
      roomNumber: e.roomNumber,
      roomType: e.roomType,
      floor: e.floor,
      description: e.description,
      occupancyStatus: e.occupancyStatus,
      cleanStatus: e.cleanStatus,
      priority: e.priority,
      lastCleanedAt: e.lastCleanedAt != null ? DateTime.parse(e.lastCleanedAt!) : null,
      estimatedCleaningTime: e.estimatedCleaningTime != null ? DateTime.parse(e.estimatedCleaningTime!) : null,
    )).toList();
  }
});

final housekeeperRoomDetailProvider = FutureProvider.family.autoDispose<HousekeepingRoomStatusModel, String>((ref, roomId) async {
  final service = ref.watch(housekeepingRoomServiceProvider);
  return await service.getRoomDetail(roomId);
});

final housekeeperControllerProvider = Provider((ref) => HousekeeperController(ref));

class HousekeeperController {
  final Ref _ref;
  HousekeeperController(this._ref);

  Future<void> completeCleaning(String roomId, List<String> imageUrls, String propertyId) async {
    await _ref.read(housekeepingRoomServiceProvider).completeCleaning(roomId, imageUrls, propertyId);
    _ref.invalidate(housekeeperRoomsProvider);
    _ref.invalidate(housekeeperRoomDetailProvider(roomId));
  }

  Future<void> scheduleCleaning(String roomId, DateTime estimatedTime, String propertyId) async {
    await _ref.read(housekeepingRoomServiceProvider).scheduleCleaning(roomId, estimatedTime, propertyId);
    _ref.invalidate(housekeeperRoomsProvider);
    _ref.invalidate(housekeeperRoomDetailProvider(roomId));
  }

  Future<void> setInProgress(String roomId, String propertyId) async {
    await _ref.read(housekeepingRoomServiceProvider).updateStatus(roomId, 'in_progress', propertyId);
    _ref.invalidate(housekeeperRoomsProvider);
    _ref.invalidate(housekeeperRoomDetailProvider(roomId));
  }
}
