import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pms_provider.dart';

class VacantRoomsScreen extends ConsumerWidget {
  const VacantRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pmsState = ref.watch(pmsProvider);
    
    // Filter rooms that are Vacant or Cleaning (i.e. not Occupied)
    final vacantRooms = pmsState.rooms.where((room) {
      return room.status.toLowerCase() == 'vacant' || 
             room.status.toLowerCase() == 'cleaning' ||
             room.status.toLowerCase() == 'maintenance';
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vacant Rooms', style: TextStyle(color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: PineBackground(
        child: vacantRooms.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hotel_class, size: 64, color: AppColors.outline),
                    SizedBox(height: 16),
                    Text(
                      'No vacant rooms',
                      style: TextStyle(
                        color: AppColors.outline,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: vacantRooms.length,
                itemBuilder: (context, index) {
                  final room = vacantRooms[index];
                  final readyStatus = room.status; // e.g. Vacant, Cleaning, Maintenance
                  
                  return PineCard(
                    onTap: () => _showRoomDetails(context, room),
                    padding: const EdgeInsets.all(16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.door_front_door,
                            size: 40,
                            color: readyStatus.toLowerCase() == 'vacant'
                                ? AppColors.primary
                                : (readyStatus.toLowerCase() == 'cleaning' ? AppColors.secondary : AppColors.error),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            room.roomNumber,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            readyStatus,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showRoomDetails(BuildContext context, RoomModel room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(context, 'Cottage Type', room.type),
                    _buildDetailRow(context, 'Room Status', room.status),
                    _buildDetailRow(context, 'Ready Status', room.status),
                    _buildDetailRow(context, 'Capacity', 'Standard'),
                    _buildDetailRow(context, 'Nightly Rate', '\$${room.price.toStringAsFixed(2)}/night'),
                    _buildDetailRow(context, 'Amenities', room.amenities.map((e) => e['name'].toString()).join(', ')),
                    _buildDetailRow(context, 'Housekeeping', room.status == 'Cleaning' ? 'Cleaning in progress' : 'Cleaned'),
                    _buildDetailRow(context, 'Maintenance', room.status == 'Maintenance' ? 'Needs Attention' : 'Good'),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
