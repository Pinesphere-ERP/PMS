import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import 'package:pinesphere_stay/features/kitchen/presentation/providers/kitchen_providers.dart';
import 'package:pinesphere_stay/features/tasks/data/models/task_model.dart';

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(kitchenTasksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Display System (KDS)'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.restaurant,
              title: 'No Active Orders',
              message: 'There are currently no active kitchen orders.',
            );
          }

          // Sort tasks: pending first, then accepted, then in_progress, then ready
          final activeTasks = tasks.where((t) => t.status != 'completed' && t.status != 'closed').toList();
          activeTasks.sort((a, b) => (a.dueAt ?? DateTime.now()).compareTo(b.dueAt ?? DateTime.now()));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: activeTasks.length,
            itemBuilder: (context, index) {
              return _OrderCard(task: activeTasks[index]);
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
}

class _OrderCard extends ConsumerWidget {
  final TaskModel task;
  const _OrderCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(kitchenTaskControllerProvider);
    final theme = Theme.of(context);
    
    // Determine card color based on status and SLA
    Color cardColor = theme.cardColor;
    if (task.status == 'ready') {
      cardColor = Colors.green.shade100;
    } else if (task.status == 'pending') {
      cardColor = Colors.orange.shade50;
    } else if (task.dueAt != null && DateTime.now().isAfter(task.dueAt!)) {
      cardColor = Colors.red.shade100; // SLA breached
    }

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${task.taskId.substring(0, 6).toUpperCase()}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (task.roomId != null)
                  Chip(
                    label: Text('Room ${task.roomId}'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  task.description ?? 'No details provided.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            if (task.remarks != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Remarks: ${task.remarks}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 16),
            _buildActionButtons(context, task, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, TaskModel task, KitchenTaskController controller) {
    switch (task.status) {
      case 'pending':
        return ElevatedButton(
          onPressed: () => controller.acceptOrder(task.taskId),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
          child: const Text('ACCEPT ORDER', style: TextStyle(color: Colors.white, fontSize: 16)),
        );
      case 'accepted':
        return ElevatedButton(
          onPressed: () => controller.startPreparing(task.taskId),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(16)),
          child: const Text('START COOKING', style: TextStyle(color: Colors.white, fontSize: 16)),
        );
      case 'in_progress':
        return ElevatedButton(
          onPressed: () => controller.markReady(task.taskId),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
          child: const Text('MARK READY', style: TextStyle(color: Colors.white, fontSize: 16)),
        );
      case 'ready':
        return ElevatedButton(
          onPressed: () => controller.markDelivered(task.taskId),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, padding: const EdgeInsets.all(16)),
          child: const Text('DELIVERED', style: TextStyle(color: Colors.white, fontSize: 16)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
