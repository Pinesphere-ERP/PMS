import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../audit/data/audit_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.maybeWhen(
      authenticated: (user) => user.name,
      orElse: () => 'Guest',
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStaggeredItem(0, _buildGreeting(context, userName)),
                  const SizedBox(height: 24),
                  _buildStaggeredItem(1, _buildQuickActions(context)),
                  const SizedBox(height: 24),
                  _buildStaggeredItem(2, _buildKPIsGrid(context, ref)),
                  const SizedBox(height: 24),
                  _buildStaggeredItem(3, _buildRecentActivity(context, ref)),
                  const SizedBox(height: 32), // bottom padding for nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.primary),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Row(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final isOnlineAsync = ref.watch(connectivityProvider);
              final isOnline = isOnlineAsync.value ?? true;
              return Icon(
                isOnline ? Icons.wifi : Icons.signal_wifi_off,
                color: isOnline ? AppColors.primary : AppColors.error,
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'PineStay',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outlineVariant, width: 2),
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBzqN2Auxk06id2mGXAAox2Cu0QkEzMO49JtE5_wtldSc3GyMNjczYC-fhllbFuFl98VR21WAg1fUCOCJeSPK536H4nKEyvdSbDH9uEl9sKkY9ajPYZGTjn7bA1cbsY6eGVeL7PbYV8ePLJ-UNLxg0j2nF6ZgLDbrzd8L2aEWt39-kwyyFTnV8A_t2YU1nfguSaspxI3b7BfiWRhiEwm6UiROn4Gbo5gMJYQSOmIUOoP0aZq0rYu6RfsA'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, String userName) {
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, MMMM d').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, $userName!',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateString,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildActionButton(context, Icons.login, 'Check-In', '/checkin')),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(context, Icons.logout, 'Check-Out', '/checkout')),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(context, Icons.cleaning_services, 'Housekeeping', '/housekeeping')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionButton(context, Icons.add_circle_outline, 'New Booking', '/rooms')),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(context, Icons.grid_view, 'Room Grid', '/rooms')),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(context, Icons.analytics_outlined, 'Reports', '/reports')),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, String route) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIsGrid(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildKPICard(context, 'Todays arrival', '${dashboardState.todaysArrivals}', AppColors.primary, Icons.luggage, onTap: () => context.push('/todays-arrivals')),
            _buildKPICard(context, 'Todays departures', '${dashboardState.todaysDepartures}', AppColors.onSurface, Icons.flight_takeoff, onTap: () => context.push('/todays-departures')),
            _buildKPICard(context, 'Occupied Rooms', '${dashboardState.occupiedRooms}', AppColors.primary, Icons.hotel, onTap: () => context.push('/occupied-rooms')),
            _buildKPICard(context, 'Vacant Rooms', '${dashboardState.vacantRooms}', AppColors.outline, Icons.vpn_key, onTap: () => context.push('/vacant-rooms')),
            _buildKPICard(context, 'Pending Checkouts', '${dashboardState.pendingCheckouts}', AppColors.secondary, Icons.hourglass_bottom, onTap: () => context.push('/pending-checkouts')),
            _buildKPICard(context, 'House Keeping', '${dashboardState.housekeepingCount}', AppColors.error, Icons.cleaning_services, onTap: () => context.push('/housekeeping')),
            _buildKPICard(context, 'Pending payments', '${dashboardState.pendingPaymentsCount}', AppColors.error, Icons.receipt_long, onTap: () => context.push('/pending-payments')),
            _buildKPICard(context, 'Revenue today', '\$${dashboardState.revenueToday.toStringAsFixed(0)}', AppColors.primaryContainer, Icons.monetization_on, onTap: () => context.push('/todays-revenue')),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(BuildContext context, String title, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final auditService = ref.watch(auditServiceProvider);
    final recentLogs = auditService.queryLogs(limit: 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
              TextButton(
                onPressed: () => context.push('/audit-logs'),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        if (recentLogs.isEmpty)
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent activity'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentLogs.length,
            itemBuilder: (context, index) {
              final log = recentLogs[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8.0),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.history, color: AppColors.primary),
                  title: Text(log.actionType ?? 'Unknown Action'),
                  subtitle: Text('By: ${log.userId}'),
                  trailing: Text(
                    DateFormat('HH:mm').format(log.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStaggeredItem(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Delay effect based on index
        final delayedValue = (value - (index * 0.1)).clamp(0.0, 1.0);
        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - delayedValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
