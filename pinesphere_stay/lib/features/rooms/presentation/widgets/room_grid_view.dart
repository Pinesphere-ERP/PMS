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
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          mainAxisExtent: 440, // Increased height for more spacious cards
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
