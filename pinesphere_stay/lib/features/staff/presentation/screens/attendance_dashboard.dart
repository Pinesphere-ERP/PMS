import 'package:flutter/material.dart';

class AttendanceDashboardScreen extends StatelessWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDailyCounters(),
          const Divider(),
          Expanded(child: _buildAttendanceList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Mark manual attendance
        },
        label: const Text('Mark Manual'),
        icon: const Icon(Icons.touch_app),
      ),
    );
  }

  Widget _buildDailyCounters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCounter('Present', '18', Colors.green),
          _buildCounter('Absent', '2', Colors.red),
          _buildCounter('Half-Day', '1', Colors.orange),
          _buildCounter('On Leave', '3', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      itemCount: 15,
      itemBuilder: (context, index) {
        bool isPresent = index % 3 != 0;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isPresent ? Colors.green[100] : Colors.red[100],
            child: Icon(
              isPresent ? Icons.check : Icons.close,
              color: isPresent ? Colors.green : Colors.red,
            ),
          ),
          title: Text('Employee ${index + 1}'),
          subtitle: Text(isPresent ? 'In: 09:00 AM • Out: 05:00 PM' : 'Absent (Not marked)'),
          trailing: Icon(isPresent ? Icons.fingerprint : null, size: 20, color: Colors.grey),
        );
      },
    );
  }
}
