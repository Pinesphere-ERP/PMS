import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import 'add_edit_user_screen.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../../../main.dart';
import '../../../sync/data/sync_service.dart';

class UserDirectoryScreen extends ConsumerWidget {
  const UserDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userListProvider);

    return Scaffold(
      body: PineBackground(
        child: Column(
          children: [
            Expanded(
              child: userAsync.when(
                data: (userList) {
                  if (userList.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: userList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = userList[index];
                      return PineCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.email ?? user.mobileNumber ?? 'No contact info'),
                          trailing: user.isPrimaryOwner
                              ? const Chip(label: Text('Owner'))
                              : PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddEditUserScreen(existingUser: user),
                                        ),
                                      );
                                    } else if (action == 'delete') {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete User'),
                                          content: const Text('Are you sure you want to delete this user?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final updatedUser = user
                                                  ..isDeleted = true
                                                  ..syncStatus = 'Pending'
                                                  ..lastModifiedHlc = DateTime.now().toUtc().toIso8601String();
                                                databaseService.userDao.put(updatedUser);
                                                ref.read(syncServiceProvider).enqueueMutation(
                                                  entityType: 'User',
                                                  entityId: user.serverId,
                                                  operation: 'DELETE',
                                                  payload: {'is_deleted': true},
                                                );
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                          onTap: () {
                            if (!user.isPrimaryOwner) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditUserScreen(existingUser: user),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditUserScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
