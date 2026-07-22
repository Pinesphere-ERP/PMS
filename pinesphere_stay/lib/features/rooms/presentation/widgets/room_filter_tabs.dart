import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class RoomFilterTabs extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  const RoomFilterTabs({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['All', 'Vacant', 'Occupied', 'Maintenance', 'Cleaning', 'Bookings'].map((filter) {
          final isSelected = activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(filter),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
              checkmarkColor: AppColors.onPrimary,
            ),
          );
        }).toList(),
      ),
    );
  }
}
