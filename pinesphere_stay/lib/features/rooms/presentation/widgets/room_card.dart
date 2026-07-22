import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pms_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../sheets/room_actions_sheet.dart';
import '../sheets/edit_room_sheet.dart';

class RoomCard extends ConsumerWidget {
  final RoomModel room;

  const RoomCard({super.key, required this.room});

  String _getMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  Widget _buildRuleTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.outline),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color edgeColor;
    Color chipBg;
    Color chipText;
    final pmsState = ref.watch(pmsProvider);

    if (room.status == 'Occupied') {
      edgeColor = AppColors.error;
      chipBg = AppColors.errorContainer;
      chipText = AppColors.onErrorContainer;
    } else if (room.status == 'Vacant') {
      edgeColor = AppColors.primary;
      chipBg = AppColors.secondaryContainer;
      chipText = AppColors.onSecondaryContainer;
    } else if (room.status == 'Maintenance') {
      edgeColor = Colors.orange;
      chipBg = Colors.orange.withValues(alpha: 0.1);
      chipText = Colors.orange;
    } else {
      edgeColor = Colors.teal;
      chipBg = Colors.teal.withValues(alpha: 0.1);
      chipText = Colors.teal;
    }

    BookingModel? activeBooking;
    if (room.status == 'Occupied' && room.currentBookingId != null) {
      activeBooking = pmsState.bookings.firstWhere(
        (b) => b.id == room.currentBookingId,
        orElse: () => BookingModel(
          id: '',
          resortId: '',
          roomId: '',
          roomNumber: '',
          guestName: 'Unknown Guest',
          guestPhone: '',
          guestIdProof: '',
          guestIdNumber: '',
          bookingSource: 'Walk-in',
          checkInDate: DateTime.now(),
          checkOutDate: DateTime.now(),
          status: 'Active',
          depositPaid: 0,
          basePriceSum: 0,
          weekendSurcharge: 0,
          seasonSurcharge: 0,
          holidaySurcharge: 0,
          extraBedCharge: 0,
          amenitiesCharge: 0,
          totalSum: 0,
        ),
      );
    }

    return PineCard(
      padding: const EdgeInsets.all(12),
      onTap: () => showRoomActionsSheet(context, room),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -12,
            top: 90,
            child: Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: edgeColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: room.images.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, imgIndex) {
                          final path = room.images[imgIndex];
                          if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
                            return Image.network(
                              path,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Icon(Icons.hotel, size: 24, color: AppColors.outline),
                              ),
                            );
                          } else {
                            return Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Icon(Icons.hotel, size: 24, color: AppColors.outline),
                              ),
                            );
                          }
                        },
                      ),
                      if (room.images.length > 1)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swipe_left_alt_outlined, color: Colors.white, size: 8),
                                const SizedBox(width: 2),
                                Text(
                                  '${room.images.length} Photos',
                                  style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => showEditRoomSheet(context, ref, room),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_outlined, color: Colors.white, size: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    room.roomNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      room.status == 'Maintenance' ? 'MAINT' : room.status.toUpperCase(),
                      style: TextStyle(color: chipText, fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                room.type,
                style: const TextStyle(color: AppColors.outline, fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (room.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  room.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 9, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 2),
              Text(
                '₹${room.price.toStringAsFixed(0)}/night',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _buildRuleTag('WE: +₹${room.weekendPrice.toStringAsFixed(0)}'),
                  _buildRuleTag('SE: +₹${room.seasonPrice.toStringAsFixed(0)}'),
                  _buildRuleTag('ExB: ₹${room.extraBedPrice.toStringAsFixed(0)}'),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: room.amenities.take(4).map((amenity) {
                  final name = amenity['name'].toString().toLowerCase();
                  IconData iconData = Icons.star_border;
                  if (name.contains('food') || name.contains('buffet') || name.contains('breakfast')) {
                    iconData = Icons.restaurant;
                  } else if (name.contains('speaker') || name.contains('audio') || name.contains('sound')) {
                    iconData = Icons.volume_up;
                  } else if (name.contains('tv') || name.contains('screen')) {
                    iconData = Icons.tv;
                  } else if (name.contains('projector')) {
                    iconData = Icons.videocam;
                  } else if (name.contains('wifi') || name.contains('internet')) {
                    iconData = Icons.wifi;
                  } else if (name.contains('pool')) {
                    iconData = Icons.pool;
                  } else if (name.contains('ac') || name.contains('air conditioning')) {
                    iconData = Icons.ac_unit;
                  }
                  return Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, size: 12, color: AppColors.primary),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              if (room.status == 'Vacant')
                Container(
                  width: double.infinity,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BOOK NOW',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              if (room.status == 'Occupied' && activeBooking != null)
                Text(
                  activeBooking.guestName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (room.status == 'Occupied' && activeBooking != null)
                Text(
                  'Checkout: ${_getMonth(activeBooking.checkOutDate)} ${activeBooking.checkOutDate.day}',
                  style: const TextStyle(color: AppColors.outline, fontSize: 10),
                ),
              if (room.status == 'Maintenance')
                const Row(
                  children: [
                    Icon(Icons.build_outlined, size: 12, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Under repair...',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange, fontSize: 10),
                    ),
                  ],
                ),
              if (room.status == 'Cleaning')
                const Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 12, color: Colors.teal),
                    SizedBox(width: 4),
                    Text(
                      'Housekeeping...',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.teal, fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
            ),
          ),
        ],
      ),
    );
  }
}
