import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinesphere_stay/core/theme/app_colors.dart';
import 'package:pinesphere_stay/core/presentation/widgets/design_system/pine_background.dart';
import 'package:pinesphere_stay/core/presentation/widgets/design_system/pine_card.dart';
import 'package:pinesphere_stay/features/housekeeping/presentation/providers/housekeeper_provider.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/auth_notifier.dart';

class HousekeeperDashboardScreen extends ConsumerWidget {
  const HousekeeperDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(housekeeperRoomsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rooms'),
        backgroundColor: AppColors.surface,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const _HousekeeperDrawer(),
      body: PineBackground(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(housekeeperRoomsProvider.future),
          child: roomsAsync.when(
            data: (rooms) {
              if (rooms.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () => context.push('/housekeeper/room/${room.roomId}'),
                      borderRadius: BorderRadius.circular(16),
                      child: PineCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _getStatusColor(room.cleanStatus).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                room.roomNumber,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(room.cleanStatus),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room.roomType ?? 'Standard Room',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.layers, size: 14, color: AppColors.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Floor ${room.floor ?? "-"}',
                                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildStatusBadge(room.cleanStatus),
                                      if (room.occupancyStatus == 'occupied') ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.purple.shade200),
                                          ),
                                          child: Text('Occupied', style: TextStyle(fontSize: 10, color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
                                        )
                                      ],
                                      if (room.priority == 'high' || room.priority == 'urgent') ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                                      ]
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.outline),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    String label = _getStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'clean': return Colors.green;
      case 'cleaning_requested': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'not_cleaned': return Colors.red;
      case 'scheduled': return Colors.purple;
      case 'verified': return Colors.teal;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'clean': return 'Clean';
      case 'cleaning_requested': return 'Requested';
      case 'in_progress': return 'In Progress';
      case 'not_cleaned': return 'Dirty';
      case 'scheduled': return 'Scheduled';
      case 'verified': return 'Verified';
      default: return 'Unknown';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'All Rooms Clean',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no assigned rooms at the moment.',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _HousekeeperDrawer extends ConsumerWidget {
  const _HousekeeperDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.centerLeft,
              child: Text(
                'PineStay\nHousekeeping',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              onTap: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
