import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/providers/roomblocks_provider.dart';

class ManagerRoomBlocksScreen extends ConsumerWidget {
  const ManagerRoomBlocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(managerRoomBlocksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager RoomBlocks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(managerRoomBlocksProvider),
          )
        ],
      ),
      body: state.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No records found.'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) => ListTile(title: Text(list[index].id.toString())),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
