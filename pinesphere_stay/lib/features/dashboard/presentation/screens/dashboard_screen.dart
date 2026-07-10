import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

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
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(context, userName),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildKPIsGrid(context),
                  const SizedBox(height: 24),
                  _buildRecentActivity(context),
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
          const Icon(Icons.signal_wifi_off, color: AppColors.primary),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onBackground,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          dateString,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildActionButton(context, Icons.add_circle_outline, 'New Booking', '/bookings')),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(context, Icons.grid_view, 'Room Grid', '/rooms')),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(context, Icons.analytics_outlined, 'Reports', '/reports')),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, String route) {
    return BentoCard(
      onTap: () {
        context.go(route);
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKPIsGrid(BuildContext context) {
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
            _buildKPICard(context, 'Todays arrival', '4', AppColors.primary, Icons.luggage, onTap: () => context.go('/todays-arrivals')),
            _buildKPICard(context, 'Todays departures', '6', AppColors.onSurface, Icons.flight_takeoff, onTap: () => context.go('/todays-departures')),
            _buildKPICard(context, 'Occupied Rooms', '12', AppColors.primary, Icons.hotel, onTap: () => context.go('/occupied-rooms')),
            _buildKPICard(context, 'Vacant Rooms', '8', AppColors.outline, Icons.vpn_key, onTap: () => context.go('/vacant-rooms')),
            _buildKPICard(context, 'Pending Checkouts', '3', AppColors.secondary, Icons.hourglass_bottom, onTap: () => context.go('/pending-checkouts')),
            _buildKPICard(context, 'House Keeping', '4', AppColors.error, Icons.cleaning_services, onTap: () => context.go('/housekeeping')),
            _buildKPICard(context, 'Pending payments', '2', AppColors.error, Icons.receipt_long, onTap: () => context.go('/pending-payments')),
            _buildKPICard(context, 'Revenue today', '\$4,250', AppColors.primaryContainer, Icons.monetization_on, onTap: () => context.go('/todays-revenue')),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(BuildContext context, String title, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return BentoCard(
      onTap: onTap ?? () {}, // empty tap handler to make card interactive
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.go('/reports');
              },
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Stack(
            children: [
              Positioned(
                left: 16, // center of 32px icon
                top: 32,
                bottom: 32,
                child: Container(
                  width: 1,
                  color: AppColors.outlineVariant,
                ),
              ),
              Column(
                children: [
                  _buildActivityItem(
                    context,
                    icon: Icons.logout,
                    iconColor: AppColors.onSecondaryContainer,
                    iconBg: AppColors.secondaryContainer,
                    title: const TextSpan(children: [
                      TextSpan(text: 'Room 102', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: ' checked out'),
                    ]),
                    timeInfo: '15 mins ago • By Alex',
                  ),
                  const SizedBox(height: 24),
                  _buildActivityItem(
                    context,
                    icon: Icons.cleaning_services,
                    iconColor: AppColors.onTertiaryContainer, // Reusing mapping
                    iconBg: AppColors.tertiaryContainer,
                    title: const TextSpan(children: [
                      TextSpan(text: 'Room 205', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: ' cleaning started'),
                    ]),
                    timeInfo: '42 mins ago • Housekeeping',
                  ),
                  const SizedBox(height: 24),
                  _buildActivityItem(
                    context,
                    icon: Icons.login,
                    iconColor: AppColors.onPrimaryFixed,
                    iconBg: AppColors.primaryFixed,
                    title: const TextSpan(children: [
                      TextSpan(text: 'John Doe', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: ' checked in (301)'),
                    ]),
                    timeInfo: '1 hour ago • By Sarah',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required TextSpan title,
    required String timeInfo,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                      ),
                  children: title.children,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeInfo,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
