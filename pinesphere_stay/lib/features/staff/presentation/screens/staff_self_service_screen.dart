import 'package:flutter/material.dart';

class StaffSelfServiceScreen extends StatelessWidget {
  const StaffSelfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPunchCard(),
            const SizedBox(height: 24),
            _buildLeaveBalanceCard(),
            const SizedBox(height: 24),
            _buildMyTasksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Current Status', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Checked In', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: null, // Disabled if already checked in
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('PUNCH IN'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('PUNCH OUT'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, size: 40, color: Colors.blue),
        title: const Text('Leave Balance'),
        subtitle: const Text('Casual: 4 • Sick: 2'),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text('Apply'),
        ),
      ),
    );
  }

  Widget _buildMyTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Card(
              child: CheckboxListTile(
                value: index == 0,
                onChanged: (val) {},
                title: Text('Clean Room 10${index + 1}'),
                subtitle: const Text('Due: Today, 2:00 PM'),
                secondary: const Icon(Icons.cleaning_services),
              ),
            );
          },
        )
      ],
    );
  }
}
