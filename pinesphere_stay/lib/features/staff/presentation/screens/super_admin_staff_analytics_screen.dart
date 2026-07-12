import 'package:flutter/material.dart';

class SuperAdminStaffAnalyticsScreen extends StatelessWidget {
  const SuperAdminStaffAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Staff Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlobalMetrics(),
            const SizedBox(height: 24),
            const Text('Role Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildRoleDistributionChart(),
            const SizedBox(height: 24),
            const Text('Properties with Sync Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildSyncIssuesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Total Staff', '1,245', Icons.public, Colors.indigo),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Avg Staff / Prop', '8.5', Icons.analytics, Colors.teal),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDistributionChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Chart Placeholder: Role Distribution', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildSyncIssuesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.sync_problem, color: Colors.orange),
            title: Text('Property XYZ - ${index + 1}'),
            subtitle: const Text('3 staff records in conflict'),
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Resolve'),
            ),
          ),
        );
      },
    );
  }
}
