import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/auth_notifier.dart';
import '../../../features/rooms/presentation/providers/pms_provider.dart';
import '../../permissions/user_role.dart';
import '../../network/tenant_provider.dart';
import '../../theme/app_colors.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessiblePropertiesAsync = ref.watch(accessiblePropertiesProvider);
    final pmsState = ref.watch(pmsProvider);
    final authState = ref.watch(authProvider);
    final role = authState.maybeWhen(authenticated: (u) => u.role, orElse: () => UserRole.reception);
    final isReceptionist = role == UserRole.reception;

    String primaryResortName = (pmsState.resorts.isNotEmpty)
        ? pmsState.resorts.first.name
        : 'Loading property...';

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Row(
              children: [
                const Icon(Icons.apartment, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'PineStay Properties',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          accessiblePropertiesAsync.when(
            data: (rawProperties) {
              return Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.check_circle, color: AppColors.primary),
                      title: Text(
                        primaryResortName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      subtitle: Text(isReceptionist ? 'Assigned Resort (Receptionist Desk)' : 'Active Property'),
                      onTap: () {
                        context.pop();
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading properties: $err'),
            ),
          ),
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Log Out', style: TextStyle(color: AppColors.error)),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
