import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/housekeeping_providers.dart';
import '../providers/housekeeper_provider.dart';

class HousekeeperDashboardScreen extends ConsumerStatefulWidget {
  const HousekeeperDashboardScreen({super.key});

  @override
  ConsumerState<HousekeeperDashboardScreen> createState() => _HousekeeperDashboardScreenState();
}

class _HousekeeperDashboardScreenState extends ConsumerState<HousekeeperDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Housekeeping'),
        backgroundColor: AppColors.surface,
        leading: Builder(
          builder: (context) {
            final canPop = Navigator.of(context).canPop();
            if (canPop) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              );
            }
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'My Tasks'),
            Tab(text: 'All Rooms'),
          ],
        ),
      ),
      drawer: const _HousekeeperDrawer(),
      body: PineBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            _MyTasksView(),
            _AllRoomsView(),
          ],
        ),
      ),
    );
  }
}

class _MyTasksView extends ConsumerWidget {
  const _MyTasksView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(housekeepingTasksProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(housekeepingTasksProvider.future),
      child: tasksAsync.when(
        data: (tasks) {
          final activeTasks = tasks.where((t) => t.status != 'completed' && t.status != 'closed' && t.status != 'inspected').toList();

          if (activeTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade200),
                  const SizedBox(height: 16),
                  const Text('All caught up!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('No rooms need cleaning right now.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeTasks.length,
            itemBuilder: (context, index) {
              final task = activeTasks[index];
              final controller = ref.read(housekeepingTaskControllerProvider);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () => context.push('/housekeeper/task/${task.serverId}'),
                  borderRadius: BorderRadius.circular(16),
                  child: PineCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _getStatusColor(task.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                task.roomNumber.isNotEmpty ? task.roomNumber : '-',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(task.status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.remarks.isNotEmpty ? task.remarks : 'Standard Cleaning',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildStatusBadge(task.status),
                                      const SizedBox(width: 6),
                                      _buildPriorityBadge(task.priority),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (task.checkoutTime.isNotEmpty) ...[
                                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Waiting: ${_formatTimeWaiting(task.checkoutTime)}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                      ] else if (task.createdAt.isNotEmpty) ...[
                                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Waiting: ${_formatTimeWaiting(task.createdAt)}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.outline),
                          ],
                        ),
                        // Quick action: START CLEANING directly from card
                        if (task.status == 'pending') ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: () async {
                                await controller.startCleaning(task.serverId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cleaning started!'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.cleaning_services, size: 18),
                              label: const Text('Start Cleaning', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Error',
          message: err.toString(),
        ),
      ),
    );
  }

  String _formatTimeWaiting(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
      if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
      return '${diff.inMinutes}m';
    } catch (e) {
      return '-';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    String label = status.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final colors = {'low': Colors.green, 'medium': Colors.orange, 'high': Colors.red, 'urgent': Colors.red};
    final color = colors[priority.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'in_progress': return Colors.purple;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }
}

class _AllRoomsView extends ConsumerWidget {
  const _AllRoomsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(housekeeperRoomsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(housekeeperRoomsProvider.future),
      child: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: PineCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getRoomStatusColor(room.cleanStatus).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          room.roomNumber,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getRoomStatusColor(room.cleanStatus),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(room.roomType ?? 'Standard Room', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              room.cleanStatus.toUpperCase(),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getRoomStatusColor(room.cleanStatus)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getRoomStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'clean': return Colors.green;
      case 'cleaning_requested': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'not_cleaned': return Colors.red;
      case 'scheduled': return Colors.purple;
      case 'verified': return Colors.teal;
      default: return Colors.grey;
    }
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
