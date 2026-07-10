import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class HousekeepingRoom {
  final String roomNumber;
  final String roomStatus; // Occupied, Vacant
  final String housekeepingStatus; // Clean, Dirty, Cleaning, Ready
  final String housekeeper;
  final DateTime lastCleaned;
  final DateTime? nextCheckIn;
  final bool maintenanceRequired;

  HousekeepingRoom({
    required this.roomNumber,
    required this.roomStatus,
    required this.housekeepingStatus,
    required this.housekeeper,
    required this.lastCleaned,
    this.nextCheckIn,
    required this.maintenanceRequired,
  });
}

class HousekeepingScreen extends StatefulWidget {
  const HousekeepingScreen({super.key});

  @override
  State<HousekeepingScreen> createState() => _HousekeepingScreenState();
}

class _HousekeepingScreenState extends State<HousekeepingScreen> {
  final List<HousekeepingRoom> _rooms = [
    HousekeepingRoom(roomNumber: '101', roomStatus: 'Occupied', housekeepingStatus: 'Clean', housekeeper: 'Alice', lastCleaned: DateTime.now().subtract(const Duration(hours: 2)), maintenanceRequired: false),
    HousekeepingRoom(roomNumber: '102', roomStatus: 'Vacant', housekeepingStatus: 'Dirty', housekeeper: 'Unassigned', lastCleaned: DateTime.now().subtract(const Duration(days: 1)), nextCheckIn: DateTime.now().add(const Duration(hours: 5)), maintenanceRequired: false),
    HousekeepingRoom(roomNumber: '103', roomStatus: 'Vacant', housekeepingStatus: 'Cleaning', housekeeper: 'Bob', lastCleaned: DateTime.now().subtract(const Duration(hours: 24)), nextCheckIn: DateTime.now().add(const Duration(hours: 2)), maintenanceRequired: false),
    HousekeepingRoom(roomNumber: '104', roomStatus: 'Vacant', housekeepingStatus: 'Ready', housekeeper: 'Alice', lastCleaned: DateTime.now().subtract(const Duration(minutes: 30)), maintenanceRequired: false),
    HousekeepingRoom(roomNumber: '105', roomStatus: 'Occupied', housekeepingStatus: 'Dirty', housekeeper: 'Unassigned', lastCleaned: DateTime.now().subtract(const Duration(days: 2)), maintenanceRequired: true),
    HousekeepingRoom(roomNumber: '201', roomStatus: 'Vacant', housekeepingStatus: 'Clean', housekeeper: 'Charlie', lastCleaned: DateTime.now().subtract(const Duration(hours: 5)), nextCheckIn: DateTime.now().add(const Duration(days: 1)), maintenanceRequired: false),
    HousekeepingRoom(roomNumber: '202', roomStatus: 'Occupied', housekeepingStatus: 'Cleaning', housekeeper: 'Charlie', lastCleaned: DateTime.now().subtract(const Duration(days: 1)), maintenanceRequired: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Housekeeping', style: TextStyle(color: AppColors.primary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a room',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return _buildRoomCard(room);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(HousekeepingRoom room) {
    return BentoCard(
      onTap: () => _showRoomDetails(room),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.meeting_room, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              room.roomNumber,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDetails(HousekeepingRoom room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                    'Room ${room.roomNumber}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(room.housekeepingStatus),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.hotel, 'Room Status', room.roomStatus),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person, 'Housekeeper', room.housekeeper),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.access_time, 'Last Cleaned', DateFormat('MMM d, y h:mm a').format(room.lastCleaned)),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.login, 'Next Check-in', room.nextCheckIn != null ? DateFormat('MMM d, y h:mm a').format(room.nextCheckIn!) : 'None scheduled'),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.build, 'Maintenance Required', room.maintenanceRequired ? 'Yes' : 'No', isAlert: room.maintenanceRequired),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'clean':
        bgColor = AppColors.secondaryContainer;
        textColor = AppColors.onSecondaryContainer;
        break;
      case 'dirty':
        bgColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        break;
      case 'cleaning':
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.onPrimaryContainer;
        break;
      case 'ready':
        bgColor = AppColors.tertiaryContainer;
        textColor = AppColors.onTertiaryContainer;
        break;
      default:
        bgColor = AppColors.surfaceVariant;
        textColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isAlert = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isAlert ? AppColors.error : AppColors.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isAlert ? AppColors.error : AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
