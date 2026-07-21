import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/providers/dashboard_provider.dart';
import 'package:pinesphere_stay/features/manager/models/dashboard_model.dart';
import 'package:pinesphere_stay/features/manager/widgets/dashboard_kpi_card.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(managerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(managerDashboardProvider);
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(managerDashboardProvider);
          await ref.read(managerDashboardProvider.future);
        },
        child: dashboardState.when(
          data: (data) => _buildDashboard(context, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading dashboard: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(managerDashboardProvider),
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ManagerDashboardResponse data) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle('Overview - ${data.date}'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            DashboardKpiCard(
              title: 'Occupancy',
              value: '${data.occupancyPercent.toStringAsFixed(1)}%',
              icon: Icons.hotel,
              color: Colors.blue,
            ),
            DashboardKpiCard(
              title: 'Arrivals / Departures',
              value: '${data.arrivals} / ${data.departures}',
              icon: Icons.flight_land,
              color: Colors.orange,
            ),
            DashboardKpiCard(
              title: 'Active Tasks',
              value: '${data.activeTasks}',
              icon: Icons.assignment,
              color: Colors.green,
            ),
            DashboardKpiCard(
              title: 'Pending Requests',
              value: '${data.pendingRequests}',
              icon: Icons.support_agent,
              color: Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Daily Operations'),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatRow('Maintenance Issues', '${data.todayMaintenance}', Icons.build),
                const Divider(),
                _buildStatRow('Cleaning Tasks', '${data.todayCleaning}', Icons.cleaning_services),
                const Divider(),
                _buildStatRow('Room Blocks', '${data.roomBlocks}', Icons.block),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Staff Availability (${data.staffOnShift} on shift)'),
        const SizedBox(height: 16),
        data.staffAvailability.isEmpty
            ? const Center(child: Text('No staff data available'))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.staffAvailability.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final staff = data.staffAvailability[index];
                  final isOnShift = staff.shiftStatus.toLowerCase() == 'on-shift';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOnShift ? Colors.green.shade100 : Colors.grey.shade200,
                      child: Icon(Icons.person, color: isOnShift ? Colors.green : Colors.grey),
                    ),
                    title: Text(staff.name),
                    subtitle: Text(staff.roleCode ?? 'Staff'),
                    trailing: Chip(
                      label: Text(staff.shiftStatus),
                      backgroundColor: isOnShift ? Colors.green.shade50 : Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isOnShift ? Colors.green.shade700 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
