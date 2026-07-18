import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/auth_notifier.dart';
import '../../network/tenant_provider.dart';
import '../../theme/app_colors.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessiblePropertiesAsync = ref.watch(accessiblePropertiesProvider);
    final selectedTenantId = ref.watch(tenantProvider);

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
            data: (properties) {
              if (properties.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No properties found.'),
                );
              }
              
              return Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final prop = properties[index];
                    final pId = prop['property_id'] as String;
                    final isSelected = pId == selectedTenantId;
                    
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.business,
                        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                      title: Text(
                        'Property: ${pId.substring(0, 8)}...',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.onSurface,
                        ),
                      ),
                      subtitle: Text('Role: ${prop['role_id']}'),
                      onTap: () {
                        ref.read(tenantProvider.notifier).setTenantId(pId);
                        context.pop(); // close drawer
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Switched property!')),
                        );
                      },
                    );
                  },
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
