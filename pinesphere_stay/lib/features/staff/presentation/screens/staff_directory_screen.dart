import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/staff_provider.dart';
import 'add_staff_screen.dart';
import '../../../sync/data/sync_service.dart';
import '../../../../main.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';

class StaffDirectoryScreen extends ConsumerWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (role) {
              ref.read(staffFilterProvider.notifier).updateRole(role);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Roles')),
              const PopupMenuItem(value: 'manager', child: Text('Managers')),
              const PopupMenuItem(value: 'receptionist', child: Text('Receptionists')),
              const PopupMenuItem(value: 'housekeeper', child: Text('Housekeepers')),
            ],
          )
        ],
      ),
      body: PineBackground(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) {
                ref.read(staffFilterProvider.notifier).updateSearch(val);
              },
              decoration: InputDecoration(
                hintText: 'Search by name, code, or mobile...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          Expanded(
            child: staffAsync.when(
              data: (staffList) {
                if (staffList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No staff members found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Try adjusting your filters or search query', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: staffList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return PineCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          child: Text(staff.name.isNotEmpty ? staff.name[0] : '?'),
                        ),
                        title: Text(staff.name),
                        subtitle: Text('${staff.roleId} • ${staff.status}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.blue),
                              onPressed: () {},
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (action) {
                                if (action == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddStaffScreen(existingStaff: staff),
                                    ),
                                  );
                                } else if (action == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Staff'),
                                      content: const Text('Are you sure you want to delete this staff member?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            final updatedStaff = staff..isDeleted = true..syncStatus = 'Pending'..lastModifiedHlc = DateTime.now().toUtc().toIso8601String();
                                            databaseService.userDao.put(updatedStaff);
                                            ref.read(syncServiceProvider).enqueueMutation(
                                              entityType: 'User',
                                              entityId: staff.serverId,
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
                          ],
                        ),
                        onTap: () {
                          // Navigate to Staff Profile
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
    );
  }
}
