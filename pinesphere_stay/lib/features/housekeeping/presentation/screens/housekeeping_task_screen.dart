import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../providers/housekeeping_providers.dart';
import '../../domain/models/housekeeping_task_entity.dart';

class HousekeepingTaskScreen extends ConsumerStatefulWidget {
  final String taskId;
  const HousekeepingTaskScreen({super.key, required this.taskId});

  @override
  ConsumerState<HousekeepingTaskScreen> createState() => _HousekeepingTaskScreenState();
}

class _HousekeepingTaskScreenState extends ConsumerState<HousekeepingTaskScreen> {
  String? _photoPath;
  final Map<String, bool> _checklist = {
    'Change bed linens': false,
    'Clean bathroom & restock towels': false,
    'Vacuum/Sweep floor': false,
    'Empty trash': false,
  };

  bool get _allChecked => _checklist.values.every((v) => v == true);

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(housekeepingTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        backgroundColor: AppColors.surface,
      ),
      body: PineBackground(
        child: tasksAsync.when(
          data: (tasks) {
            final taskList = tasks.where((t) => t.serverId == widget.taskId).toList();
            if (taskList.isEmpty) {
              return const Center(child: Text('Task not found'));
            }
            final task = taskList.first;
            return _buildContent(context, task);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HousekeepingTaskEntity task) {
    final controller = ref.read(housekeepingTaskControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.roomNumber.isNotEmpty ? 'Room ${task.roomNumber}' : 'General',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    _buildStatusBadge(task.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.remarks.isNotEmpty ? task.remarks : 'Standard Cleaning',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (task.status == 'in_progress') ...[
            Text('Checklist', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            PineCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: _checklist.keys.map((item) {
                  return CheckboxListTile(
                    title: Text(item),
                    value: _checklist[item],
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _checklist[item] = val ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Proof of Work', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() => _photoPath = picked.path);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: PineCard(
                padding: const EdgeInsets.all(32),
                child: _photoPath == null
                    ? Column(
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('Tap to take photo', style: TextStyle(color: AppColors.primary)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_photoPath!), fit: BoxFit.cover, height: 200, width: double.infinity),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 48),
          _buildActionButtons(task, controller),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status.toUpperCase();

    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'accepted': color = Colors.blue; break;
      case 'in_progress': color = Colors.purple; break;
      case 'completed': color = Colors.green; break;
      default: color = Colors.grey; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButtons(HousekeepingTaskEntity task, HousekeepingTaskController controller) {
    if (task.status == 'pending') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => controller.acceptTask(task.serverId),
        child: const Text('ACCEPT TASK', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    } else if (task.status == 'accepted') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => controller.startCleaning(task.serverId),
        child: const Text('START CLEANING', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    } else if (task.status == 'in_progress') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: (_allChecked && _photoPath != null)
            ? () async {
                await controller.markCompleted(
                  task.serverId,
                  photoPath: _photoPath,
                  roomId: task.roomId,
                  propertyId: task.propertyId,
                );
                if (mounted) context.pop();
              }
            : null,
        child: const Text('MARK COMPLETED', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox.shrink();
  }
}
