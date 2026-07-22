import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinesphere_stay/core/theme/app_colors.dart';
import 'package:pinesphere_stay/core/presentation/widgets/design_system/pine_background.dart';
import 'package:pinesphere_stay/features/housekeeping/presentation/providers/housekeeper_provider.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/auth_notifier.dart';

class HousekeeperRoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  const HousekeeperRoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<HousekeeperRoomDetailScreen> createState() => _HousekeeperRoomDetailScreenState();
}

class _HousekeeperRoomDetailScreenState extends ConsumerState<HousekeeperRoomDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      final propertyId = auth.maybeWhen(authenticated: (u) => u.propertyId, orElse: () => null);
      if (propertyId != null) {
        // Set room to in_progress if opened by housekeeper
        ref.read(housekeeperControllerProvider).setInProgress(widget.roomId, propertyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(housekeeperRoomDetailProvider(widget.roomId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Detail'),
        backgroundColor: AppColors.surface,
      ),
      body: PineBackground(
        child: roomAsync.when(
          data: (room) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            room.roomNumber,
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: AppColors.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          room.roomType ?? 'Standard Room',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Floor ${room.floor ?? "-"} • ${room.occupancyStatus.toUpperCase()}',
                          style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 32),
                        if (room.description != null && room.description!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Text(
                              room.description!,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        if (room.imageUrls != null && room.imageUrls!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text('Cleaning Photos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: room.imageUrls!.length,
                            itemBuilder: (context, index) {
                              final path = room.imageUrls![index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: path.startsWith('http') 
                                    ? Image.network(path, fit: BoxFit.cover)
                                    : Image.file(File(path), fit: BoxFit.cover),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (room.cleanStatus != 'clean' && room.cleanStatus != 'verified')
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.close,
                          color: Colors.red,
                          label: 'Schedule',
                          onTap: () => _showScheduleDialog(context, room.roomId),
                        ),
                        _buildActionButton(
                          context,
                          icon: Icons.check,
                          color: Colors.green,
                          label: 'Complete',
                          onTap: () => context.push('/housekeeper/room/${room.roomId}/upload'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _showScheduleDialog(BuildContext context, String roomId) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && context.mounted) {
      final now = DateTime.now();
      final estimated = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      final auth = ref.read(authProvider);
      final propertyId = auth.maybeWhen(authenticated: (u) => u.propertyId, orElse: () => '');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
      
      await ref.read(housekeeperControllerProvider).scheduleCleaning(roomId, estimated, propertyId!);
      
      if (context.mounted) {
        Navigator.pop(context); // close loading
        context.pop(); // close detail screen
      }
    }
  }
}
