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
  String? _beforePhotoPath;
  String? _afterPhotoPath;
  Map<String, bool> _checklist = {};
  bool _checklistLoaded = false;
  bool _isProcessing = false;

  // Damage report fields
  bool _showDamageForm = false;
  final _damageDescController = TextEditingController();
  String _damageCategory = 'Furniture';
  String _damageSeverity = 'medium';
  String? _damagePhotoPath;

  static const _defaultChecklist = {
    'Change bed linens': false,
    'Clean bathroom & restock towels': false,
    'Vacuum/Sweep floor': false,
    'Empty trash': false,
    'Check & restock minibar': false,
    'Inspect for damage': false,
  };

  bool get _allChecked => _checklist.isNotEmpty && _checklist.values.every((v) => v == true);

  @override
  void dispose() {
    _damageDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(housekeepingTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleaning Task'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: PineBackground(
        child: tasksAsync.when(
          data: (tasks) {
            final taskList = tasks.where((t) => t.serverId == widget.taskId).toList();
            if (taskList.isEmpty) {
              return const Center(child: Text('Task not found'));
            }
            final task = taskList.first;

            // Load checklist from task's checklistStatusMap if not yet loaded
            if (!_checklistLoaded) {
              _checklistLoaded = true;
              final taskChecklist = task.checklistStatusMap;
              if (taskChecklist != null && taskChecklist.isNotEmpty) {
                // Use the checklist from the task (populated from config on checkout)
                _checklist = Map<String, bool>.from(taskChecklist);
              } else {
                _checklist = Map<String, bool>.from(_defaultChecklist);
              }
            }
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
          // ── Task Header ──────────────────────────────────────────
          PineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.roomNumber.isNotEmpty ? 'Room ${task.roomNumber}' : 'General Cleaning',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (task.checkoutTime.isNotEmpty)
                          Text(
                            'Checked out: ${_formatDate(task.checkoutTime)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                      ],
                    ),
                    _buildStatusBadge(task.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.remarks.isNotEmpty ? task.remarks : 'Standard Cleaning',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityChip(task.priority),
                    if (task.guestName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.person_outline, size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(task.guestName, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Cleaning Checklist (shown when in_progress) ──────────
          if (task.status == 'in_progress') ...[
            const SizedBox(height: 24),
            Text('Cleaning Checklist',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'All items must be completed before you can finish.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            PineCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: _checklist.entries.map((entry) {
                  return CheckboxListTile(
                    title: Text(entry.key),
                    value: entry.value,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _checklist[entry.key] = val ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            // ── Before Photo ──────────────────────────────────────
            const SizedBox(height: 24),
            Text('Before Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPhotoCapture(
              label: 'Take BEFORE photo',
              photoPath: _beforePhotoPath,
              onTap: () => _pickPhoto(isBefore: true),
            ),

            // ── After Photo ───────────────────────────────────────
            const SizedBox(height: 16),
            Text('After Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPhotoCapture(
              label: 'Take AFTER photo (required)',
              photoPath: _afterPhotoPath,
              onTap: () => _pickPhoto(isBefore: false),
              isRequired: true,
            ),

            // ── Damage Report ─────────────────────────────────────
            const SizedBox(height: 24),
            _buildDamageReportSection(task, controller),
          ],

          // ── Action Buttons ────────────────────────────────────────
          const SizedBox(height: 32),
          _buildActionButtons(context, task, controller),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhotoCapture({
    required String label,
    required String? photoPath,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: PineCard(
        padding: const EdgeInsets.all(24),
        child: photoPath == null
            ? Column(
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: isRequired ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isRequired ? AppColors.primary : AppColors.onSurfaceVariant,
                      fontWeight: isRequired ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (isRequired)
                    const Text('Required', style: TextStyle(fontSize: 11, color: Colors.red)),
                ],
              )
            : Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(photoPath), fit: BoxFit.cover, height: 180, width: double.infinity),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDamageReportSection(HousekeepingTaskEntity task, HousekeepingTaskController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => setState(() => _showDamageForm = !_showDamageForm),
          icon: Icon(_showDamageForm ? Icons.remove_circle_outline : Icons.add_circle_outline),
          label: Text(_showDamageForm ? 'Hide Damage Report' : 'Report Damage'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (_showDamageForm) ...[
          const SizedBox(height: 16),
          PineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Damage Category', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _damageCategory,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: ['Furniture', 'Electrical', 'AC', 'Plumbing', 'TV', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _damageCategory = val ?? 'Furniture'),
                ),
                const SizedBox(height: 12),
                Text('Severity', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _damageSeverity,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: (val) => setState(() => _damageSeverity = val ?? 'medium'),
                ),
                const SizedBox(height: 12),
                Text('Description', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _damageDescController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Describe the damage in detail...',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.camera);
                    if (picked != null) setState(() => _damagePhotoPath = picked.path);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _damagePhotoPath == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text('Attach damage photo'),
                            ],
                          )
                        : Image.file(File(_damagePhotoPath!), height: 120, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _damageDescController.text.isEmpty
                        ? null
                        : () async {
                            setState(() => _isProcessing = true);
                            try {
                              await controller.reportDamage(task.serverId, {
                                'room_id': task.roomId,
                                'category': _damageCategory,
                                'severity': _damageSeverity,
                                'issue_description': _damageDescController.text,
                                'photo_url': _damagePhotoPath,
                                'housekeeping_task_id': task.serverId,
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Damage report submitted. Maintenance team notified.'), backgroundColor: Colors.orange),
                                );
                                setState(() {
                                  _showDamageForm = false;
                                  _damageDescController.clear();
                                  _damagePhotoPath = null;
                                });
                              }
                            } finally {
                              if (mounted) setState(() => _isProcessing = false);
                            }
                          },
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('Submit Damage Report', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status.replaceAll('_', ' ').toUpperCase();
    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'in_progress': color = Colors.purple; break;
      case 'completed': color = Colors.green; break;
      default: color = Colors.grey; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 11)),
    );
  }

  Widget _buildPriorityChip(String priority) {
    final colors = {'low': Colors.green, 'medium': Colors.orange, 'high': Colors.red, 'urgent': Colors.red};
    final color = colors[priority.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, HousekeepingTaskEntity task, HousekeepingTaskController controller) {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (task.status == 'pending') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () async {
          setState(() => _isProcessing = true);
          try {
            await controller.startCleaning(task.serverId);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cleaning started! Room status updated.'), backgroundColor: Colors.blue),
            );
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },
        icon: const Icon(Icons.cleaning_services, color: Colors.white),
        label: const Text('START CLEANING', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }

    if (task.status == 'in_progress') {
      final canComplete = _allChecked && _afterPhotoPath != null;
      return Column(
        children: [
          if (!canComplete)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !_allChecked
                          ? 'Complete all checklist items first.'
                          : 'Take an AFTER photo to complete.',
                      style: const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: canComplete ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: canComplete
                  ? () async {
                      setState(() => _isProcessing = true);
                      try {
                        await controller.markCompleted(
                          task.serverId,
                          photoPath: _afterPhotoPath,
                          roomId: task.roomId,
                          propertyId: task.propertyId,
                          checklistStatus: Map<String, dynamic>.from(_checklist),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Room cleaned! Reception has been notified.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        if (!mounted) return;
                        context.pop();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      } finally {
                        if (mounted) setState(() => _isProcessing = false);
                      }
                    }
                  : null,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('MARK COMPLETED', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    if (task.status == 'completed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Task Completed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                if (task.completedAt.isNotEmpty)
                  Text('at ${_formatDate(task.completedAt)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _pickPhoto({required bool isBefore}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      setState(() {
        if (isBefore) {
          _beforePhotoPath = picked.path;
        } else {
          _afterPhotoPath = picked.path;
        }
      });
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month} $hour:$min';
    } catch (_) {
      return isoString;
    }
  }
}
