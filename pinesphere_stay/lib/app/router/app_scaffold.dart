import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/permissions/permission_matrix.dart';
import '../../core/presentation/widgets/role_guard.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../core/presentation/widgets/connectivity_banner.dart';

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
        body: ConnectivityBanner(child: navigationShell),
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
                RoleGuard(module: Module.dashboard, child: _buildNavItem(context, index: 0, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard')),
                RoleGuard(module: Module.roomManagement, child: _buildNavItem(context, index: 1, icon: Icons.bed_outlined, activeIcon: Icons.bed_rounded, label: 'Rooms')),
                RoleGuard(module: Module.bookingManagement, child: _buildNavItem(context, index: 2, icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Bookings')),
                RoleGuard(module: Module.reports, child: _buildNavItem(context, index: 3, icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded, label: 'Reports')),
                RoleGuard(module: Module.settings, child: _buildNavItem(context, index: 4, icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildDrawer(BuildContext context, AuthState authState, WidgetRef ref) {
    final user = authState.maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );

    final userName = user?.name ?? 'Guest';
    final userRole = user?.role.displayName ?? 'Unknown Role';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'G';

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userRole.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildSectionHeader('CORE'),
                _buildPremiumDrawerItem(context, Module.dashboard, Icons.dashboard_rounded, 'Dashboard', () => navigationShell.goBranch(0)),
                _buildPremiumDrawerItem(context, Module.roomManagement, Icons.bed_rounded, 'Rooms', () => navigationShell.goBranch(1)),
                _buildPremiumDrawerItem(context, Module.bookingManagement, Icons.calendar_month_rounded, 'Bookings', () => navigationShell.goBranch(2)),
                _buildPremiumDrawerItem(context, Module.reports, Icons.analytics_rounded, 'Reports', () => navigationShell.goBranch(3)),
                
                _buildSectionHeader('OPERATIONS'),
                _buildPremiumDrawerItem(context, Module.checkInCheckOut, Icons.login_rounded, 'Check-in', () => context.push('/checkin')),
                _buildPremiumDrawerItem(context, Module.checkInCheckOut, Icons.logout_rounded, 'Check-out', () => context.push('/checkout')),
                _buildPremiumDrawerItem(context, Module.payments, Icons.payments_rounded, 'Payments', () => context.push('/payments')),
                _buildPremiumDrawerItem(context, Module.housekeeping, Icons.cleaning_services_rounded, 'Housekeeping', () => context.push('/housekeeping')),
                _buildPremiumDrawerItem(context, Module.housekeeping, Icons.assignment_rounded, 'Requests', () => context.push('/requests')),
                
                _buildSectionHeader('MANAGEMENT'),
                _buildPremiumDrawerItem(context, Module.propertyOnboarding, Icons.business_rounded, 'Property Settings', () => context.push('/property-settings')),
                _buildPremiumDrawerItem(context, Module.userRoleManagement, Icons.manage_accounts_rounded, 'User & Roles', () => context.push('/user-roles')),
                _buildPremiumDrawerItem(context, Module.staffManagement, Icons.badge_rounded, 'Staff', () => context.push('/staff')),
                _buildPremiumDrawerItem(context, Module.deviceManagement, Icons.devices_rounded, 'Devices', () => context.push('/device-registration')),
                _buildPremiumDrawerItem(context, Module.auditLogs, Icons.history_rounded, 'Audit Logs', () => context.push('/audit-logs')),
              ],
            ),
          ),
          
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SafeArea(
              top: false,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context); // close drawer
                  ref.read(authProvider.notifier).logout();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.errorContainer,
                  foregroundColor: AppColors.onErrorContainer,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.outline,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildPremiumDrawerItem(BuildContext context, Module module, IconData icon, String title, VoidCallback onTap) {
    return RoleGuard(
      module: module,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.outlineVariant, size: 18),
              ],
            ),
          ),
        ),
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
