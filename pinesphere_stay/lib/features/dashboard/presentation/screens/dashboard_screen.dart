import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _buildGreeting(context),
                  const SizedBox(height: 24),
                  _buildRevenueCard(context),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildRoomStats(context),
                  const SizedBox(height: 24),
                  _buildOperationsStats(context),
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
      title: Row(
        children: [
          const Icon(Icons.signal_wifi_off, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            'Pinesphere Forest Resort',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
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

  Widget _buildGreeting(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, MMMM d').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, Sarah',
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

  Widget _buildRevenueCard(BuildContext context) {
    return BentoCard(
      backgroundColor: AppColors.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              Icons.payments,
              size: 140,
              color: AppColors.onPrimaryContainer.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REVENUE TODAY',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onPrimaryContainer.withOpacity(0.9),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$4,250',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.onPrimaryContainer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+12% from yesterday',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildActionButton(context, Icons.add_circle_outline, 'New Booking')),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(context, Icons.grid_view, 'Room Grid')),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(context, Icons.analytics_outlined, 'Reports')),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label) {
    return BentoCard(
      onTap: () {},
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

  Widget _buildRoomStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Room Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildStatCard(context, AppColors.primary, 'Occupied', '12', '60% Capacity'),
              const SizedBox(width: 16),
              _buildStatCard(context, AppColors.outline, 'Vacant', '8', 'Available Now'),
              const SizedBox(width: 16),
              _buildStatCard(context, AppColors.error, 'Cleaning', '4', 'Due soon'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, Color dotColor, String label, String value, String subtitle) {
    return SizedBox(
      width: 160,
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsStats(BuildContext context) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Operations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildOpStat(context, '4', 'Check-ins', AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildOpStat(context, '6', 'Check-outs', AppColors.onSurface)),
              const SizedBox(width: 8),
              Expanded(child: _buildOpStat(context, '2', 'Pending Pay', AppColors.error)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpStat(BuildContext context, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: color),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
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
              onPressed: () {},
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
