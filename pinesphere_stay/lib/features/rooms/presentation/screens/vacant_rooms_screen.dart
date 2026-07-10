import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class VacantRoomsScreen extends StatelessWidget {
  const VacantRoomsScreen({super.key});

  final List<Map<String, String>> vacantRooms = const [
    {
      'roomNumber': 'C-101', 'type': 'Premium Cottage', 'status': 'Vacant', 'readyStatus': 'Ready',
      'capacity': '2 Adults, 1 Child', 'bedType': 'King Size', 'rate': '\$120/night',
      'amenities': 'WiFi, AC, Minibar, Balcony', 'lastCheckout': 'Oct 24, 10:00 AM',
      'lastCleaned': 'Oct 24, 01:30 PM', 'housekeeping': 'Cleaned', 'maintenance': 'Good',
      'nextReservation': 'Oct 27, 2024', 'daysVacant': '1', 'housekeeper': 'Sarah'
    },
    {
      'roomNumber': 'C-102', 'type': 'Standard Cottage', 'status': 'Vacant', 'readyStatus': 'Cleaning',
      'capacity': '2 Adults', 'bedType': 'Queen Size', 'rate': '\$90/night',
      'amenities': 'WiFi, AC, TV', 'lastCheckout': 'Today, 11:00 AM',
      'lastCleaned': 'Pending', 'housekeeping': 'Cleaning in progress', 'maintenance': 'Good',
      'nextReservation': 'None', 'daysVacant': '0', 'housekeeper': 'Mike'
    },
    {
      'roomNumber': 'C-103', 'type': 'Family Villa', 'status': 'Vacant', 'readyStatus': 'Maintenance',
      'capacity': '4 Adults, 2 Children', 'bedType': '2 King Size', 'rate': '\$250/night',
      'amenities': 'WiFi, AC, Kitchen, Private Pool', 'lastCheckout': 'Oct 20, 11:00 AM',
      'lastCleaned': 'Oct 21, 10:00 AM', 'housekeeping': 'Cleaned', 'maintenance': 'AC Repair',
      'nextReservation': 'Nov 02, 2024', 'daysVacant': '4', 'housekeeper': 'Jane'
    },
    {
      'roomNumber': 'C-104', 'type': 'Premium Cottage', 'status': 'Vacant', 'readyStatus': 'Ready',
      'capacity': '2 Adults, 1 Child', 'bedType': 'King Size', 'rate': '\$120/night',
      'amenities': 'WiFi, AC, Minibar, Balcony', 'lastCheckout': 'Oct 22, 09:00 AM',
      'lastCleaned': 'Oct 22, 02:00 PM', 'housekeeping': 'Cleaned', 'maintenance': 'Good',
      'nextReservation': 'None', 'daysVacant': '3', 'housekeeper': 'Sarah'
    },
    {
      'roomNumber': 'C-105', 'type': 'Standard Cottage', 'status': 'Vacant', 'readyStatus': 'Ready',
      'capacity': '2 Adults', 'bedType': 'Queen Size', 'rate': '\$90/night',
      'amenities': 'WiFi, AC, TV', 'lastCheckout': 'Oct 23, 10:00 AM',
      'lastCleaned': 'Oct 23, 12:30 PM', 'housekeeping': 'Cleaned', 'maintenance': 'Good',
      'nextReservation': 'Tomorrow', 'daysVacant': '2', 'housekeeper': 'Mike'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vacant Rooms'),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
      ),
      body: GridView.builder(
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
          return BentoCard(
            onTap: () => _showRoomDetails(context, room),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.door_front_door,
                  size: 40,
                  color: room['readyStatus'] == 'Ready'
                      ? AppColors.primary
                      : (room['readyStatus'] == 'Cleaning' ? AppColors.secondary : AppColors.error),
                ),
                const SizedBox(height: 12),
                Text(
                  room['roomNumber']!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  room['readyStatus']!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRoomDetails(BuildContext context, Map<String, String> room) {
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
                      'Room ${room['roomNumber']}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(context, 'Cottage Type', room['type']!),
                    _buildDetailRow(context, 'Room Status', room['status']!),
                    _buildDetailRow(context, 'Ready Status', room['readyStatus']!),
                    _buildDetailRow(context, 'Capacity', room['capacity']!),
                    _buildDetailRow(context, 'Bed Type', room['bedType']!),
                    _buildDetailRow(context, 'Nightly Rate', room['rate']!),
                    _buildDetailRow(context, 'Amenities', room['amenities']!),
                    _buildDetailRow(context, 'Last Check-out', room['lastCheckout']!),
                    _buildDetailRow(context, 'Last Cleaned', room['lastCleaned']!),
                    _buildDetailRow(context, 'Housekeeping', room['housekeeping']!),
                    _buildDetailRow(context, 'Maintenance', room['maintenance']!),
                    _buildDetailRow(context, 'Next Reservation', room['nextReservation']!),
                    _buildDetailRow(context, 'Days Vacant', room['daysVacant']!),
                    _buildDetailRow(context, 'Housekeeper', room['housekeeper']!),
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
