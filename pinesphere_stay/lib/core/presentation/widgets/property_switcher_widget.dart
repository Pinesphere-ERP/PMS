import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/core/auth/session_context.dart';
import 'package:pinesphere_stay/core/network/dio_client.dart';
import 'package:pinesphere_stay/features/auth/domain/models/accessible_property_model.dart';

class PropertySwitcherWidget extends ConsumerWidget {
  const PropertySwitcherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionContextProvider);
    final accessibleProperties = session.accessibleProperties;
    final activePropertyId = session.activePropertyId;

    if (accessibleProperties.isEmpty) {
      return Text(
        'PineStay',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
      );
    }

    final activeProperty = accessibleProperties.firstWhere(
      (p) => p.propertyId == activePropertyId,
      orElse: () => accessibleProperties.first,
    );

    final hasMultipleProperties = accessibleProperties.length > 1;

    if (!hasMultipleProperties) {
      return Text(
        activeProperty.propertyName.isNotEmpty ? activeProperty.propertyName : 'Unnamed Property',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
      );
    }

    return PopupMenuButton<AccessiblePropertyModel>(
      initialValue: activeProperty,
      tooltip: 'Switch Property',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      offset: const Offset(0, 8),
      elevation: 4,
      onSelected: (property) {
        if (property.propertyId != activePropertyId) {
          ref
              .read(sessionContextProvider.notifier)
              .switchProperty(property.propertyId, ref.read(secureStorageProvider));
        }
      },
      itemBuilder: (context) {
        return accessibleProperties.map((property) {
          final isSelected = property.propertyId == activePropertyId;
          return PopupMenuItem<AccessiblePropertyModel>(
            value: property,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.business_rounded,
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        property.propertyName.isNotEmpty ? property.propertyName : 'Unnamed Property',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.black87,
                        ),
                      ),
                      Text(
                        'OWNER',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business_rounded,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                activeProperty.propertyName.isNotEmpty ? activeProperty.propertyName : 'Unnamed Property',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

}
