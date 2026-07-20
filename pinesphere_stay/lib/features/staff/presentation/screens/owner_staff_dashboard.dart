import 'package:flutter/material.dart';
import 'add_staff_screen.dart';
import '../../user_role_management/presentation/screens/role_directory_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/staff_provider.dart';

class OwnerStaffDashboardScreen extends ConsumerWidget {
  const OwnerStaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Role Management',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoleDirectoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            staffAsync.when(
              data: (staff) => _buildMetricsGrid(staff.length.toString()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Pending Tasks & Alerts'),
            _buildTasksList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Recently Added Staff'),
            staffAsync.when(
              data: (staff) => _buildRecentStaffList(staff),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStaffScreen()),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildMetricsGrid(String totalStaff) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard('Total Staff', totalStaff, Icons.people, Colors.blue),
        _buildMetricCard('Present Today', '0', Icons.check_circle, Colors.green),
        _buildMetricCard('On Leave', '0', Icons.beach_access, Colors.orange),
        _buildMetricCard('Pending Leaves', '0', Icons.pending_actions, Colors.red),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTasksList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: ListTile(
            leading: const Icon(Icons.assignment_late, color: Colors.red),
            title: Text('Housekeeping Task #${index + 1}'),
            subtitle: const Text('Overdue by 2 hours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildRecentStaffList(List<dynamic> staffList) {
    if (staffList.isEmpty) return const Text('No staff found.');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: staffList.length > 3 ? 3 : staffList.length,
      itemBuilder: (context, index) {
        final staff = staffList[index];
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(staff.name.isNotEmpty ? staff.name[0] : '?'),
            ),
            title: Text(staff.name),
            subtitle: Text(staff.roleId),
            trailing: Chip(
              label: Text(staff.status),
              backgroundColor: Colors.green[100],
              labelStyle: const TextStyle(color: Colors.green),
            ),
          ),
        );
      },
    );
  }
}
