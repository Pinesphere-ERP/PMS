import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/pms_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/permissions/user_role.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../bookings/presentation/screens/create_booking_sheet.dart';
import 'edit_room_sheet.dart';
import 'checkout_bill_sheet.dart';

String _getMonth(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[date.month - 1];
}

void showRoomActionsSheet(BuildContext context, RoomModel room) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final pmsState = ref.watch(pmsProvider);
          final authState = ref.watch(authProvider);
          final isReceptionist = authState.maybeWhen(authenticated: (u) => u.role == UserRole.reception, orElse: () => true);
          final liveRoom = pmsState.rooms.firstWhere((r) => r.id == room.id, orElse: () => room);
          
          BookingModel? activeBooking;
          if (liveRoom.status == 'Occupied') {
            activeBooking = pmsState.bookings.firstWhere(
              (b) => b.roomId == liveRoom.id && b.status == 'Active',
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

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Room ${liveRoom.roomNumber} Actions',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Row(
                      children: [
                        if (!isReceptionist) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                            onPressed: () {
                              Navigator.pop(context); // Close actions sheet
                              showEditRoomSheet(context, ref, liveRoom); // Open edit dialog
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text('Delete Room'),
                                  content: Text('Are you sure you want to delete Room ${liveRoom.roomNumber}? This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                      onPressed: () async {
                                        Navigator.pop(dialogCtx); // Close confirm dialog
                                        Navigator.pop(context); // Close actions sheet
                                        await ref.read(pmsProvider.notifier).deleteRoom(liveRoom.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Room ${liveRoom.roomNumber} deleted successfully!')),
                                          );
                                        }
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                Text('Type: ${liveRoom.type} | Price: ₹${liveRoom.price.toStringAsFixed(0)}/night', style: const TextStyle(color: AppColors.outline)),
                const Divider(height: 24),
                if (liveRoom.status == 'Vacant')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_home_work_outlined),
                        label: const Text('Book Room & Check-In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close actions sheet
                          showCreateBookingSheet(context, ref, preselectedRoomId: liveRoom.id);
                        },
                      ),
                    ),
                  ),
                const Text('Change Status Manually:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.outline)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: ['Vacant', 'Occupied', 'Maintenance', 'Cleaning'].map((status) {
                      final isSelected = liveRoom.status == status;
                      Color btnColor = AppColors.primary;
                      if (status == 'Occupied') btnColor = AppColors.error;
                      if (status == 'Maintenance') btnColor = Colors.orange;
                      if (status == 'Cleaning') btnColor = Colors.teal;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            status,
                            style: TextStyle(
                              color: isSelected ? Colors.white : btnColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: btnColor,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          onSelected: (val) async {
                            if (val) {
                              if (status == 'Occupied') {
                                // Ask for occupancy end date
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                  helpText: 'Select Occupancy End Date',
                                );
                                if (pickedDate != null) {
                                  final nights = pickedDate.difference(DateTime.now()).inDays.clamp(1, 90);
                                  final newManualBooking = BookingModel(
                                    id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                                    resortId: liveRoom.resortId,
                                    roomId: liveRoom.id,
                                    roomNumber: liveRoom.roomNumber,
                                    guestName: 'Manual Occupancy Override',
                                    guestPhone: 'N/A',
                                    guestIdProof: 'N/A',
                                    guestIdNumber: 'N/A',
                                    bookingSource: 'Manual',
                                    checkInDate: DateTime.now(),
                                    checkOutDate: pickedDate,
                                    status: 'Active',
                                    depositPaid: 0.0,
                                    basePriceSum: liveRoom.price * nights,
                                    weekendSurcharge: 0.0,
                                    seasonSurcharge: 0.0,
                                    holidaySurcharge: 0.0,
                                    extraBedCharge: 0.0,
                                    amenitiesCharge: 0.0,
                                    totalSum: liveRoom.price * nights,
                                  );
                                  ref.read(pmsProvider.notifier).createBooking(newManualBooking);
                                  if (context.mounted) {
                                    Navigator.pop(context); // Close actions sheet
                                    Navigator.pop(context); // Pop RoomGridScreen to go back
                                    context.go('/bookings');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Room ${liveRoom.roomNumber} set to Occupied manually until ${_getMonth(pickedDate)} ${pickedDate.day}!')),
                                    );
                                  }
                                }
                              } else {
                                ref.read(pmsProvider.notifier).updateRoomStatus(liveRoom.id, status);
                              }
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                if (liveRoom.status == 'Occupied')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Checkout Guest & Settle Bill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        showCheckoutBillSheet(context, ref, activeBooking!, liveRoom);
                      },
                    ),
                  ),
                if (liveRoom.status == 'Maintenance')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.build_circle),
                      label: const Text('Complete Maintenance (Set Vacant)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        ref.read(pmsProvider.notifier).updateRoomStatus(liveRoom.id, 'Vacant');
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Room ${liveRoom.roomNumber} is now VACANT and ready to book!')),
                        );
                      },
                    ),
                  ),
                if (liveRoom.status == 'Cleaning')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Complete Cleaning (Set Vacant)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        ref.read(pmsProvider.notifier).updateRoomStatus(liveRoom.id, 'Vacant');
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Room ${liveRoom.roomNumber} has been cleaned and is now VACANT!')),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text('Share Room Details & Photos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      const portalBaseUrl = String.fromEnvironment('PORTAL_URL', defaultValue: 'https://portal.pinesphere.com');
                      final portalUrl = '$portalBaseUrl/share/room/${liveRoom.id}?num=${liveRoom.roomNumber}&type=${Uri.encodeComponent(liveRoom.type)}&price=${liveRoom.price}&images=${Uri.encodeComponent(liveRoom.images.join(','))}';
                      Clipboard.setData(ClipboardData(text: portalUrl));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Room link copied to clipboard!\nRoom #${liveRoom.roomNumber} details embedded!'),
                          action: SnackBarAction(
                            label: 'OK',
                            onPressed: () {},
                            textColor: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
