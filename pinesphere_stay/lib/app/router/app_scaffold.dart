import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/permissions/permission_matrix.dart';
import '../../core/presentation/widgets/role_guard.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../core/presentation/widgets/connectivity_banner.dart';
import '../../core/permissions/user_role.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.navigationShell,
    required this.routerState,
  });

  final StatefulNavigationShell navigationShell;
  final GoRouterState routerState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isHousekeeper = authState.maybeWhen(
      authenticated: (user) => user.role.name.toLowerCase() == 'housekeeping',
      orElse: () => false,
    );

    final role = authState.maybeWhen(
      authenticated: (user) => user.role,
      orElse: () => null,
    );
    final isAccountant = role == UserRole.accountant;

    // If housekeeping role, we don't use this scaffold at all (no bottom nav)
    // The HousekeeperDashboardScreen provides its own Scaffold + Drawer
    if (isHousekeeper) {
      return navigationShell;
    }

    final location = routerState.uri.toString();
    final isPropertyActive = location.contains('accountant');

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
                  RoleGuard(module: Module.dashboard, child: _buildNavItem(context, index: 0, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', isPropertyActive: isPropertyActive)),
                  if (isAccountant)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/accountant-dashboard'),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPropertyActive ? AppColors.secondaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.apartment_rounded,
                                color: isPropertyActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                                size: 24,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Property',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isPropertyActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
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
                    ),
                  RoleGuard(module: Module.roomManagement, child: _buildNavItem(context, index: 1, icon: Icons.bed_outlined, activeIcon: Icons.bed_rounded, label: 'Rooms', isPropertyActive: isPropertyActive)),
                  RoleGuard(module: Module.bookingManagement, child: _buildNavItem(context, index: 2, icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Bookings', isPropertyActive: isPropertyActive)),
                  RoleGuard(module: Module.reports, child: _buildNavItem(context, index: 3, icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded, label: 'Reports', isPropertyActive: isPropertyActive)),
                  RoleGuard(module: Module.settings, child: _buildNavItem(context, index: 4, icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings', isPropertyActive: isPropertyActive)),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85 > 320 ? 320 : MediaQuery.of(context).size.width * 0.85,
      child: Stack(
        children: [
          // Glassmorphic Background
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
            child: BackdropFilter(
              filter: dart_ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: AppColors.surface.withValues(alpha: 0.85),
                child: SafeArea(
                  child: Column(
                    children: [
                      // User Profile Header (Modern Floating Card style)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      userRole.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
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
                      
                      const SizedBox(height: 8),
                      const Divider(indent: 24, endIndent: 24, color: Colors.black12),
                      
                      // Drawer Items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildSectionHeader('CORE'),
                            _buildPremiumDrawerItem(context, Module.dashboard, Icons.dashboard_rounded, 'Dashboard', () => navigationShell.goBranch(0)),
                            _buildPremiumDrawerItem(context, Module.roomManagement, Icons.bed_rounded, 'Rooms', () => navigationShell.goBranch(1)),
                            _buildPremiumDrawerItem(context, Module.bookingManagement, Icons.calendar_month_rounded, 'Bookings', () => navigationShell.goBranch(2)),
                            _buildPremiumDrawerItem(context, Module.reports, Icons.analytics_rounded, 'Reports', () => navigationShell.goBranch(3)),
                            
                            const SizedBox(height: 12),
                            _buildSectionHeader('OPERATIONS'),
                            _buildPremiumDrawerItem(context, Module.checkInCheckOut, Icons.login_rounded, 'Check-in', () => context.push('/checkin')),
                            _buildPremiumDrawerItem(context, Module.checkInCheckOut, Icons.logout_rounded, 'Check-out', () => context.push('/checkout')),
                            _buildPremiumDrawerItem(context, Module.payments, Icons.payments_rounded, 'Payments', () => context.push('/payments')),
                            _buildPremiumDrawerItem(context, Module.housekeeping, Icons.cleaning_services_rounded, 'Housekeeping', () => context.push('/housekeeping')),
                            _buildPremiumDrawerItem(context, Module.housekeeping, Icons.assignment_rounded, 'Requests', () => context.push('/requests')),
                            
                            const SizedBox(height: 12),
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
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // close drawer
                            ref.read(authProvider.notifier).logout();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.errorContainer.withValues(alpha: 0.8),
                            foregroundColor: AppColors.error,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildNavItem(BuildContext context, {required int index, required IconData icon, required IconData activeIcon, required String label, required bool isPropertyActive}) {
    final isActive = isPropertyActive ? false : (navigationShell.currentIndex == index);

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
