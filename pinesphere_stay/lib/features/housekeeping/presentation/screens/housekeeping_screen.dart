import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import 'package:pinesphere_stay/features/housekeeping/presentation/providers/housekeeping_providers.dart';
import 'package:pinesphere_stay/features/tasks/data/models/task_model.dart';

class HousekeepingScreen extends ConsumerWidget {
  const HousekeepingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(housekeepingTasksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cleaning Tasks'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final activeTasks = tasks.where((t) => t.status != 'completed' && t.status != 'closed').toList();
          if (activeTasks.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeTasks.length,
            itemBuilder: (context, index) {
              return _TaskSwipeCard(task: activeTasks[index]);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Action for creating a manual maintenance ticket
        },
        label: const Text('Report Issue'),
        icon: const Icon(Icons.report_problem),
        backgroundColor: Colors.red.shade100,
        foregroundColor: Colors.red.shade900,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
}

class _TaskSwipeCard extends ConsumerWidget {
  final TaskModel task;
  const _TaskSwipeCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(housekeepingTaskControllerProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                task.roomId != null ? 'Room ${task.roomId}' : 'General Area',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  task.description ?? 'Standard Checkout Cleaning',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              trailing: _buildStatusBadge(task.status, theme),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildBigActionButton(task, controller),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    Color bgColor;
    String label;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade100;
        label = 'NEW';
        break;
      case 'accepted':
        bgColor = Colors.blue.shade100;
        label = 'ACCEPTED';
        break;
      case 'in_progress':
        bgColor = Colors.yellow.shade200;
        label = 'CLEANING';
        break;
      default:
        bgColor = Colors.grey.shade200;
        label = status.toUpperCase();
    }

    return Chip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: bgColor,
    );
  }

  Widget _buildBigActionButton(TaskModel task, HousekeepingTaskController controller) {
    switch (task.status) {
      case 'pending':
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => controller.acceptTask(task.taskId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ACCEPT TASK', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
        );
      case 'accepted':
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => controller.startCleaning(task.taskId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('START CLEANING', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
        );
      case 'in_progress':
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => controller.markCompleted(task.taskId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('MARK CLEAN', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
