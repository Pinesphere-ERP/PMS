import 'package:flutter/material.dart';
import 'user_directory_screen.dart';
import 'role_directory_screen.dart';

class UserRoleDashboardScreen extends StatelessWidget {
  const UserRoleDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User & Role Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Roles'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserDirectoryScreen(),
            RoleDirectoryScreen(),
          ],
        ),
      ),
    );
  }
}
