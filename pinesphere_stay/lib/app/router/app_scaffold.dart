import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/permissions/permission_matrix.dart';
import '../../core/presentation/widgets/role_guard.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isHousekeeper = authState.maybeWhen(
      authenticated: (user) => user.role.name.toLowerCase() == 'housekeeping',
      orElse: () => false,
    );

    // If housekeeping role, we don't use this scaffold at all (no bottom nav)
    // The HousekeeperDashboardScreen provides its own Scaffold + Drawer
    if (isHousekeeper) {
      return navigationShell;
    }

    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: _buildDrawer(context, authState, ref),
        body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, -1),
              blurRadius: 3,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, index: 0, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
                _buildNavItem(context, index: 1, icon: Icons.bed_outlined, activeIcon: Icons.bed_rounded, label: 'Rooms'),
                _buildNavItem(context, index: 2, icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Bookings'),
                _buildNavItem(context, index: 3, icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded, label: 'Reports'),
                _buildNavItem(context, index: 4, icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildDrawer(BuildContext context, AuthState authState, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.signal_wifi_off, color: AppColors.primary, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pinesphere Stay', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                      authState.maybeWhen(
                        authenticated: (user) => Text(user.role.displayName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, Module.dashboard, Icons.dashboard, 'Dashboard', () => navigationShell.goBranch(0)),
                _buildDrawerItem(context, Module.roomManagement, Icons.bed, 'Room Management', () => navigationShell.goBranch(1)),
                _buildDrawerItem(context, Module.bookingManagement, Icons.book_online, 'Booking Management', () => navigationShell.goBranch(2)),
                _buildDrawerItem(context, Module.checkInCheckOut, Icons.login, 'Check-in', () => context.push('/checkin')),
                _buildDrawerItem(context, Module.checkInCheckOut, Icons.logout, 'Check-out', () => context.push('/checkout')),
                _buildDrawerItem(context, Module.housekeeping, Icons.cleaning_services, 'Housekeeping & Maintenance', () => context.push('/housekeeping')),
                _buildDrawerItem(context, Module.guestManagement, Icons.people, 'Guest Management', () => _showComingSoon(context)),
                _buildDrawerItem(context, Module.payments, Icons.payments, 'Payments', () => context.push('/payments')),
                _buildDrawerItem(context, Module.reports, Icons.analytics, 'Reports', () => navigationShell.goBranch(3)),
                _buildDrawerItem(context, Module.auditLogs, Icons.history, 'Audit Logs', () => context.push('/audit-logs')),
                const Divider(),
                _buildDrawerItem(context, Module.propertyOnboarding, Icons.business, 'Property Settings', () => context.push('/property-settings')),
                _buildDrawerItem(context, Module.userRoleManagement, Icons.manage_accounts, 'User & Role Management', () => _showComingSoon(context)),
                _buildDrawerItem(context, Module.staffManagement, Icons.badge, 'Staff Management', () => _showComingSoon(context)),
                _buildDrawerItem(context, Module.deviceManagement, Icons.devices, 'Device Management', () => context.push('/device-registration')),
                _buildDrawerItem(context, Module.subscriptionManagement, Icons.subscriptions, 'Subscription Management', () => _showComingSoon(context)),
                _buildDrawerItem(context, Module.settings, Icons.settings, 'Settings', () => navigationShell.goBranch(4)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Logout', style: TextStyle(color: AppColors.error)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, Module module, IconData icon, String title, VoidCallback onTap) {
    return RoleGuard(
      module: module,
      child: ListTile(
        leading: Icon(icon, color: AppColors.onSurfaceVariant),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        onTap: () {
          Navigator.pop(context); // close drawer
          onTap();
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This feature is currently in development.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required int index, required IconData icon, required IconData activeIcon, required String label}) {
    final isActive = navigationShell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
