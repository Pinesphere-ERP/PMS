import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/domain/models/accessible_property_model.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/permissions/permission_matrix.dart';
import '../../../../core/permissions/user_role.dart';
import '../../../audit/data/audit_service.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';
import '../../../../core/presentation/widgets/property_switcher_widget.dart';
import 'package:pinesphere_stay/core/auth/session_context.dart';



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
                  _buildStaggeredItem(0, _buildGreeting(context, ref, userName)),
                  const SizedBox(height: 24),
                  _buildStaggeredItem(1, _buildQuickActions(context, ref)),
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
          const Expanded(
            child: PropertySwitcherWidget(),
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

  Widget _buildGreeting(BuildContext context, WidgetRef ref, String userName) {
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, MMMM d').format(now);
    final pmsState = ref.watch(pmsProvider);
    final authState = ref.watch(authProvider);
    final role = authState.maybeWhen(authenticated: (u) => u.role, orElse: () => UserRole.reception);
    final isReceptionist = role == UserRole.reception;
    final session = ref.watch(sessionContextProvider);
    final String? assignedPropertyId = session.activePropertyId ??
        authState.maybeWhen(authenticated: (u) => u.propertyId, orElse: () => null);

    String resortName = '';
    String resortLocation = '';

    // Step 1: Match from user's assigned accessible properties in session/auth
    final userProps = authState.maybeWhen(
      authenticated: (u) => u.accessibleProperties,
      orElse: () => session.accessibleProperties,
    );

    AccessiblePropertyModel? matchedUserProp;
    if (userProps.isNotEmpty) {
      try {
        matchedUserProp = userProps.firstWhere(
          (p) => p.propertyId == assignedPropertyId,
          orElse: () => userProps.first,
        );
      } catch (_) {}
    }

    if (matchedUserProp != null) {
      resortName = matchedUserProp.propertyName;
      if (resortName.isEmpty) resortName = 'Unnamed Property';
    }

    // Step 2: Match from loaded pmsState.resorts by property ID
    ResortModel? matchedResort;
    if (assignedPropertyId != null && assignedPropertyId.isNotEmpty && pmsState.resorts.isNotEmpty) {
      try {
        matchedResort = pmsState.resorts.firstWhere(
          (r) => r.id.toString().trim() == assignedPropertyId.toString().trim() ||
                 r.id.toString().contains(assignedPropertyId.toString()) ||
                 assignedPropertyId.toString().contains(r.id.toString()),
        );
      } catch (_) {}
    }

    if (matchedResort != null) {
      if (matchedResort.name.isNotEmpty && matchedResort.name != 'Unnamed Property') {
        resortName = matchedResort.name;
      }
      if (matchedResort.location.isNotEmpty && matchedResort.location != 'Unknown') {
        resortLocation = matchedResort.location;
      }
    }

    // Step 3: Only if user has NO assigned properties at all, fallback to first resort
    if (resortName.isEmpty && assignedPropertyId == null && pmsState.resorts.isNotEmpty) {
      resortName = pmsState.resorts.first.name;
      resortLocation = pmsState.resorts.first.location;
    }

    void sharePropertyLocation() {
      final loc = resortLocation.isNotEmpty ? resortLocation : resortName;
      final encodedLocation = Uri.encodeComponent(loc);
      final mapsUrl = 'https://maps.google.com/?q=$encodedLocation';
      final shareText = '📍 *$resortName*\n'
          '📌 Location: ${resortLocation.isNotEmpty ? resortLocation : "Property Address"}\n'
          '🗺️ Google Maps Directions: $mapsUrl\n'
          '🌐 Guest Web Portal: http://localhost:3000\n'
          '📞 Reception Desk Helpline Available';

      _showShareLocationModal(context, resortName, resortLocation.isNotEmpty ? resortLocation : "Property Address", mapsUrl, shareText);
    }

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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resortName.isNotEmpty ? resortName : 'Property',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                resortLocation.isNotEmpty ? resortLocation : 'Property Location',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isReceptionist ? 'Reception Desk' : 'Assigned',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: sharePropertyLocation,
                      icon: const Icon(Icons.share_location_rounded, size: 18, color: AppColors.primary),
                      label: const Text(
                        'Share Location & Directions',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showShareLocationModal(
    BuildContext context,
    String name,
    String location,
    String mapsUrl,
    String shareText,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share Property Location',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(location, style: const TextStyle(fontSize: 12, color: AppColors.outline))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareText));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📍 Location & Directions copied! Ready to paste & send on WhatsApp!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Share WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareText));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location & Directions copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Info'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final role = authState.maybeWhen(authenticated: (u) => u.role, orElse: () => UserRole.reception);
    final isReceptionist = role == UserRole.reception;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildActionButton(context, Icons.login, 'Check-In', '/checkin')),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(context, Icons.logout, 'Check-Out', '/checkout')),
            const SizedBox(width: 12),
            if (isReceptionist)
              Expanded(child: _buildActionButton(context, Icons.payments, 'Collect Payment', '/pending-payments'))
            else
              Expanded(child: _buildActionButton(context, Icons.cleaning_services, 'Housekeeping', '/housekeeping')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionButton(context, Icons.add_circle_outline, 'New Booking', '/rooms')),
            const SizedBox(width: 12),
            if (isReceptionist)
              Expanded(child: _buildActionButton(context, Icons.book_online, 'Bookings', '/bookings'))
            else
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
        onTap: () => context.push(route),
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
    final dashboardAsync = ref.watch(dashboardMetricsProvider);
    final authState = ref.watch(authProvider);
    final role = authState.maybeWhen(authenticated: (u) => u.role, orElse: () => UserRole.reception);
    final canHousekeeping = PermissionMatrix.hasAccess(role, Module.housekeeping);
    
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
        dashboardAsync.when(
          data: (dashboardState) => GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKPICard(context, 'Today Check-in', '${dashboardState.todaysArrivals}', AppColors.primary, Icons.login, onTap: () => context.push('/todays-arrivals')),
              _buildKPICard(context, 'Today Check-outs', '${dashboardState.todaysDepartures}', AppColors.onSurface, Icons.logout, onTap: () => context.push('/todays-departures')),
              _buildKPICard(context, 'Occupied Rooms', '${dashboardState.occupiedRooms}', AppColors.primary, Icons.hotel, onTap: () => context.push('/occupied-rooms')),
              _buildKPICard(context, 'Vacant Rooms', '${dashboardState.vacantRooms}', AppColors.outline, Icons.vpn_key, onTap: () => context.push('/vacant-rooms')),
              _buildKPICard(context, 'Pending Checkouts', '${dashboardState.pendingCheckouts}', AppColors.secondary, Icons.hourglass_bottom, onTap: () => context.push('/pending-checkouts')),
              if (canHousekeeping)
                _buildKPICard(context, 'House Keeping', '${dashboardState.housekeepingCount}', AppColors.error, Icons.cleaning_services, onTap: () => context.push('/housekeeping')),
              _buildKPICard(context, 'Pending payments', '${dashboardState.pendingPaymentsCount}', AppColors.error, Icons.receipt_long, onTap: () => context.push('/pending-payments')),
              _buildKPICard(context, 'Revenue today', '\$${dashboardState.revenueToday.toStringAsFixed(0)}', AppColors.primaryContainer, Icons.monetization_on, onTap: () => context.push('/todays-revenue')),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error loading dashboard: $error')),
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
              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_toggle_off, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.actionType ?? 'Unknown Action',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By: ${log.userId}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(log.timestamp),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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
