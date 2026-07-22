import 'package:flutter/material.dart';
import '../providers/pms_provider.dart';
import 'room_card.dart';

class RoomGridView extends StatelessWidget {
  final List<RoomModel> rooms;

  const RoomGridView({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 420, // Increased height to prevent overflow
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final room = rooms[index];
            return RoomCard(room: room);
          },
          childCount: rooms.length,
        ),
      ),
    );
  }
}
