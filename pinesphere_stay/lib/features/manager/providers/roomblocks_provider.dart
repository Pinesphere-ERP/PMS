import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

import 'package:pinesphere_stay/features/manager/models/room_block_model.dart';

final managerRoomBlocksProvider = FutureProvider.autoDispose<List<RoomBlock>>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getRoomBlocks();
  return data.map((e) => RoomBlock.fromJson(e as Map<String, dynamic>)).toList();
});
