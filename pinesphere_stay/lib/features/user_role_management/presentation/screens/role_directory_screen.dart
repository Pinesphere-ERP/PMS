import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/role_provider.dart';
import 'add_edit_role_screen.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../../../main.dart';
import '../../../sync/data/sync_service.dart';

class RoleDirectoryScreen extends ConsumerWidget {
  const RoleDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(roleListProvider);

    return Scaffold(
      body: PineBackground(
        child: Column(
          children: [
            Expanded(
              child: roleAsync.when(
                data: (roleList) {
                  if (roleList.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No roles found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: roleList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final role = roleList[index];
                      return PineCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: const CircleAvatar(
                            child: Icon(Icons.admin_panel_settings),
                          ),
                          title: Text(role.roleName),
                          subtitle: Text(role.description ?? role.roleCode),
                          trailing: role.isSystemRole
                              ? const Chip(label: Text('System'))
                              : PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddEditRoleScreen(existingRole: role),
                                        ),
                                      );
                                    } else if (action == 'delete') {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Role'),
                                          content: const Text('Are you sure you want to delete this role?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final updatedRole = role
                                                  ..isDeleted = true
                                                  ..syncStatus = 'Pending'
                                                  ..lastModifiedHlc = DateTime.now().toUtc().toIso8601String();
                                                databaseService.roleDao.put(updatedRole);
                                                ref.read(syncServiceProvider).enqueueMutation(
                                                  entityType: 'Role',
                                                  entityId: role.serverId,
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
                            if (!role.isSystemRole) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditRoleScreen(existingRole: role),
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
            MaterialPageRoute(builder: (context) => const AddEditRoleScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
