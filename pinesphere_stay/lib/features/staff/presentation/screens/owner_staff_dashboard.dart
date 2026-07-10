import 'package:flutter/material.dart';

class OwnerStaffDashboardScreen extends StatelessWidget {
  const OwnerStaffDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Overview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle('Pending Tasks & Alerts'),
            _buildTasksList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Recently Added Staff'),
            _buildRecentStaffList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add staff action
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard('Total Staff', '24', Icons.people, Colors.blue),
        _buildMetricCard('Present Today', '18', Icons.check_circle, Colors.green),
        _buildMetricCard('On Leave', '2', Icons.beach_access, Colors.orange),
        _buildMetricCard('Pending Leaves', '3', Icons.pending_actions, Colors.red),
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

  Widget _buildRecentStaffList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('S${index + 1}'),
            ),
            title: Text('Staff Name ${index + 1}'),
            subtitle: const Text('Joined 2 days ago'),
            trailing: Chip(
              label: const Text('Active'),
              backgroundColor: Colors.green[100],
              labelStyle: const TextStyle(color: Colors.green),
            ),
          ),
        );
      },
    );
  }
}
