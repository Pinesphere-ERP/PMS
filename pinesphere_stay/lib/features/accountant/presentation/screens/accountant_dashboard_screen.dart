import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/accountant_dashboard_provider.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';
import '../../../../core/network/connectivity_provider.dart';

class AccountantDashboardScreen extends ConsumerWidget {
  const AccountantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.maybeWhen(
      authenticated: (user) => user.name,
      orElse: () => 'Accountant',
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
                  _buildStaggeredItem(1, _buildKPIsGrid(context, ref)),
                  const SizedBox(height: 24),
                  _buildStaggeredItem(2, _buildRecentGuests(context, ref)),
                  const SizedBox(height: 32),
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
              'PineStay - Accountant',
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

  Widget _buildKPIsGrid(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(accountantDashboardProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Financial Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
        ),
        dashboardAsync.when(
          data: (dashboardState) => GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKPICard(context, 'Accounting', '₹${dashboardState.accounting.toStringAsFixed(0)}', AppColors.primary, Icons.account_balance, onTap: () => context.push('/payments')),
              _buildKPICard(context, 'Income', '₹${dashboardState.income.toStringAsFixed(0)}', Colors.green.shade700, Icons.trending_up, onTap: () => context.push('/accountant/income')),
              _buildKPICard(context, 'Expenses', '₹${dashboardState.expenses.toStringAsFixed(0)}', AppColors.error, Icons.trending_down, onTap: () => context.push('/accountant/expenses')),
              _buildKPICard(context, 'Profit', '₹${dashboardState.profit.toStringAsFixed(0)}', AppColors.primaryContainer, Icons.monetization_on, onTap: () => context.push('/accountant/profit-loss')),
              _buildKPICard(context, 'GST & Invoices', '${dashboardState.invoices} Invoices (GST: ₹${dashboardState.gst.toStringAsFixed(0)})', AppColors.secondary, Icons.description, onTap: () => context.push('/accountant/gst-invoices')),
              _buildKPICard(context, 'Reports', '${dashboardState.reports}', AppColors.onSurface, Icons.analytics, onTap: () => context.push('/accountant/reports')),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error loading dashboard: $error')),
        ),
      ],
    );
  }

  Widget _buildKPICard(BuildContext context, String title, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                      fontSize: 24,
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

  Widget _buildRecentGuests(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(accountantDashboardProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Recent Guests / Bookings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
        ),
        dashboardAsync.when(
          data: (dashboardState) {
            final recentGuests = dashboardState.recentGuests;
            if (recentGuests.isEmpty) {
              return const Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent guests'),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentGuests.length,
              itemBuilder: (context, index) {
                final guest = recentGuests[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text(guest['guest_name'] ?? 'Unknown Guest'),
                    subtitle: Text('Room: ${guest['room_number']} • Status: ${guest['status']}'),
                    trailing: Text(
                      '₹${guest['amount_due']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: (guest['amount_due'] ?? 0) > 0 ? AppColors.error : Colors.green.shade700,
                          ),
                    ),
                    onTap: () {
                      context.push('/accountant-guest/${guest['id']}');
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Center(child: Text('Error loading guests')),
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
