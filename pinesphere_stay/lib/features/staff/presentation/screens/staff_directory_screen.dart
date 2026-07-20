import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';

class StaffDirectoryScreen extends StatelessWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          )
        ],
      ),
      body: PineBackground(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, code, or mobile...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 10,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return PineCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text('Employee ${index + 1}'),
                  subtitle: Text('EMP00${index + 1} • Housekeeping'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.blue),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                    onTap: () {
                      // Navigate to Staff Profile
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}
