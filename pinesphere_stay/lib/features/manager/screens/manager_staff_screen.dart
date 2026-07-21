import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/providers/staff_provider.dart';

class ManagerStaffScreen extends ConsumerWidget {
  const ManagerStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffState = ref.watch(managerStaffProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(managerStaffProvider),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(managerStaffProvider);
          await ref.read(managerStaffProvider.future);
        },
        child: staffState.when(
          data: (staffList) {
            if (staffList.isEmpty) {
              return const Center(child: Text('No staff found.'));
            }
            return ListView.separated(
              itemCount: staffList.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: staff.onShift ? Colors.green.shade100 : Colors.grey.shade200,
                    child: Icon(Icons.person, color: staff.onShift ? Colors.green : Colors.grey),
                  ),
                  title: Text(staff.name),
                  subtitle: Text('${staff.roleCode} • ${staff.email}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: staff.onShift ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      staff.onShift ? 'On-shift' : 'Off-shift',
                      style: TextStyle(
                        color: staff.onShift ? Colors.green.shade700 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Task Assignment Dialog placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assign Task dialog coming soon')),
          );
        },
        child: const Icon(Icons.add_task),
      ),
    );
  }
}
