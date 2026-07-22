import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';
import '../../../../core/theme/app_colors.dart';

void showCreateBookingSheet(BuildContext context, WidgetRef ref, {String? preselectedRoomId}) {
  final pmsState = ref.read(pmsProvider);
  final pmsNotifier = ref.read(pmsProvider.notifier);
  final vacantRooms = pmsState.rooms.where((r) => r.status == 'Vacant').toList();

  if (vacantRooms.isEmpty && preselectedRoomId == null) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Vacant Rooms'),
        content: const Text('All rooms are currently occupied or being cleaned. Please clear or clean a room first.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
    return;
  }

  // Nested helper to replace the private state method
  Widget buildSummaryBillRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.outline)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String getMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  String? selectedResortId;
  String? selectedRoomId = preselectedRoomId;

  if (selectedRoomId != null) {
    final pr = pmsState.rooms.firstWhere((r) => r.id == selectedRoomId, orElse: () => pmsState.rooms.first);
    selectedResortId = pr.resortId;
  } else {
    selectedResortId = pmsState.resorts.isNotEmpty ? pmsState.resorts.first.id : null;
  }

  List<RoomModel> getFilteredRooms(String? resortId) {
    if (resortId == null) return [];
    final list = vacantRooms.where((r) => r.resortId == resortId).toList();
    if (preselectedRoomId != null) {
      final pr = pmsState.rooms.firstWhere((r) => r.id == preselectedRoomId, orElse: () => pmsState.rooms.first);
      if (pr.resortId == resortId && !list.any((r) => r.id == pr.id)) {
        list.add(pr);
      }
    }
    return list;
  }

  final initialRooms = getFilteredRooms(selectedResortId);
  if (selectedRoomId == null && initialRooms.isNotEmpty) {
    selectedRoomId = initialRooms.first.id;
  }

  final guestNameCtrl = TextEditingController();
    final guestPhoneCtrl = TextEditingController();
    final guestIdCtrl = TextEditingController();
    String selectedIdProof = 'Address';
    String selectedSource = 'Walk-in';
    final depositCtrl = TextEditingController(text: '0');


    // Pricing Rule states
    bool isSeason = false;
    bool isWeekend = false;
    bool isHoliday = false;
    int extraBedsCount = 0;

    // Selected standard amenities list
    final List<String> selectedAmenities = [];

    // Stay dates
    DateTime checkInDate = DateTime.now();
    DateTime checkOutDate = DateTime.now().add(const Duration(days: 2));

    // Dynamic manual amenities
    final List<Map<String, dynamic>> manualAmenities = [];
    final bookingAmenityNameCtrl = TextEditingController();
    final bookingAmenityPriceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final currentFilteredRooms = getFilteredRooms(selectedResortId);
            
            final selectedRoom = selectedRoomId != null && currentFilteredRooms.any((r) => r.id == selectedRoomId)
                ? currentFilteredRooms.firstWhere((r) => r.id == selectedRoomId)
                : (currentFilteredRooms.isNotEmpty
                    ? currentFilteredRooms.first
                    : RoomModel(
                        id: 'dummy',
                        roomNumber: 'None',
                        type: 'No Room Available',
                        price: 0.0,
                        seasonPrice: 0.0,
                        weekendPrice: 0.0,
                        holidayPrice: 0.0,
                        extraBedPrice: 0.0,
                        amenities: const [],
                        status: 'Vacant',
                        resortId: selectedResortId ?? '',
                        images: const [],
                      ));
            
            final selectedResort = pmsState.resorts.firstWhere(
              (res) => res.id == selectedResortId,
              orElse: () => pmsState.resorts.isNotEmpty
                  ? pmsState.resorts.first
                  : ResortModel(
                      id: 'dummy_resort',
                      name: 'No Resort Selected',
                      image: '',
                      location: 'Unknown',
                    ),
            );

            final nights = checkOutDate.difference(checkInDate).inDays.clamp(1, 365);
            final double basePriceSum = selectedRoom.price * nights;
            final double weekendSum = isWeekend ? (selectedRoom.weekendPrice * nights) : 0.0;
            final double seasonSum = isSeason ? (selectedRoom.seasonPrice * nights) : 0.0;
            final double holidaySum = isHoliday ? (selectedRoom.holidayPrice * nights) : 0.0;
            final double extraBedSum = selectedRoom.extraBedPrice * extraBedsCount * nights;

            // Calculate standard amenities flat sum
            final double amenitiesSum = selectedRoom.amenities
                .where((a) => selectedAmenities.contains(a['name']))
                .map<double>((a) => (a['price'] as num).toDouble())
                .fold(0.0, (sum, val) => sum + val);

            // Calculate manual amenities flat sum
            final double manualAmenitiesSum = manualAmenities
                .map<double>((a) => (a['price'] as num).toDouble())
                .fold(0.0, (sum, val) => sum + val);

            final double totalInvoice = basePriceSum + weekendSum + seasonSum + holidaySum + extraBedSum + amenitiesSum + manualAmenitiesSum;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Create New Booking',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedResortId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Select Resort / Property', border: OutlineInputBorder()),
                        items: pmsState.resorts.map((resort) {
                          return DropdownMenuItem(
                            value: resort.id,
                            child: Text(resort.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setSheetState(() {
                          selectedResortId = val;
                          final filtered = getFilteredRooms(selectedResortId);
                          selectedRoomId = filtered.isNotEmpty ? filtered.first.id : null;
                          selectedAmenities.clear();
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRoomId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Select Room (Vacant Only)', border: OutlineInputBorder()),
                        items: currentFilteredRooms.map((room) {
                          return DropdownMenuItem(
                            value: room.id,
                            child: Text('Room ${room.roomNumber} - ${room.type} (₹${room.price.toStringAsFixed(0)}/night)', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setSheetState(() {
                          selectedRoomId = val;
                          selectedAmenities.clear();
                        }),
                      ),
                      if (selectedRoomId == null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'No vacant rooms available for this property.',
                          style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),
                      TextField(
                        controller: guestNameCtrl,
                        decoration: const InputDecoration(labelText: 'Guest Name', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: guestPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: guestIdCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Guest Address', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedSource,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Booking Source', border: OutlineInputBorder()),
                              items: ['Walk-in', 'Phone', 'WhatsApp', 'Online'].map((src) {
                                return DropdownMenuItem(value: src, child: Text(src, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (val) => setSheetState(() => selectedSource = val ?? 'Walk-in'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: depositCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Initial Deposit (₹)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // STAY DATES PICKER
                      InkWell(
                        onTap: () async {
                          final pickedRange = await showDateRangePicker(
                            context: context,
                            initialDateRange: DateTimeRange(start: checkInDate, end: checkOutDate),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            helpText: 'Select Stay Dates',
                          );
                          if (pickedRange != null) {
                            setSheetState(() {
                              checkInDate = pickedRange.start;
                              checkOutDate = pickedRange.end;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Stay Dates', style: TextStyle(fontSize: 10, color: AppColors.outline)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${checkInDate.day} ${getMonth(checkInDate)} - ${checkOutDate.day} ${getMonth(checkOutDate)} ($nights Nights)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const Icon(Icons.date_range_outlined, size: 20, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // SURCHARGES / OPTIONS
                      const Text('Surcharges & Pricing Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: Text('Weekend (+₹${selectedRoom.weekendPrice.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11)),
                              value: isWeekend,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) => setSheetState(() => isWeekend = val ?? false),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: Text('Season (+₹${selectedRoom.seasonPrice.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11)),
                              value: isSeason,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) => setSheetState(() => isSeason = val ?? false),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: Text('Holiday (+₹${selectedRoom.holidayPrice.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11)),
                              value: isHoliday,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) => setSheetState(() => isHoliday = val ?? false),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Text('Extra Beds: ', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                DropdownButton<int>(
                                  value: extraBedsCount,
                                  items: [0, 1, 2, 3].map((cnt) {
                                    return DropdownMenuItem(
                                      value: cnt, 
                                      child: Text('$cnt (+₹${(selectedRoom.extraBedPrice * cnt).toStringAsFixed(0)})', style: const TextStyle(fontSize: 11))
                                    );
                                  }).toList(),
                                  onChanged: (val) => setSheetState(() => extraBedsCount = val ?? 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // STANDARD AMENITIES SELECTOR
                      if (selectedRoom.amenities.isNotEmpty) ...[
                        const Text('Select Room Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: selectedRoom.amenities.map((a) {
                            final name = a['name'] as String;
                            final price = a['price'] as num;
                            final isSel = selectedAmenities.contains(name);
                            return FilterChip(
                              label: Text('$name (₹$price)'),
                              selected: isSel,
                              onSelected: (val) {
                                setSheetState(() {
                                  if (val) {
                                    selectedAmenities.add(name);
                                  } else {
                                    selectedAmenities.remove(name);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // CUSTOM MANUAL AMENITIES
                      const Text('Add Custom Manual Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bookingAmenityNameCtrl,
                              decoration: const InputDecoration(labelText: 'Amenity Name', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: bookingAmenityPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Price (₹)', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onPressed: () {
                              if (bookingAmenityNameCtrl.text.isEmpty || bookingAmenityPriceCtrl.text.isEmpty) return;
                              final pr = double.tryParse(bookingAmenityPriceCtrl.text) ?? 0.0;
                              setSheetState(() {
                                manualAmenities.add({'name': bookingAmenityNameCtrl.text, 'price': pr});
                                bookingAmenityNameCtrl.clear();
                                bookingAmenityPriceCtrl.clear();
                              });
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      if (manualAmenities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: manualAmenities.map((ma) {
                            return Chip(
                              label: Text('${ma['name']} (₹${ma['price']})'),
                              onDeleted: () => setSheetState(() => manualAmenities.remove(ma)),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // BILL BREAKDOWN INVOICE CARD
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invoice Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                            const SizedBox(height: 8),
                            buildSummaryBillRow('Base Rent (₹${selectedRoom.price}/night x $nights)', '₹$basePriceSum'),
                            if (isWeekend) buildSummaryBillRow('Weekend Surcharge (₹${selectedRoom.weekendPrice}/night x $nights)', '₹$weekendSum'),
                            if (isSeason) buildSummaryBillRow('Season Surcharge (₹${selectedRoom.seasonPrice}/night x $nights)', '₹$seasonSum'),
                            if (isHoliday) buildSummaryBillRow('Holiday Surcharge (₹${selectedRoom.holidayPrice}/night x $nights)', '₹$holidaySum'),
                            if (extraBedsCount > 0) buildSummaryBillRow('Extra Bed (₹${selectedRoom.extraBedPrice}/bed x $extraBedsCount x $nights)', '₹$extraBedSum'),
                            if (amenitiesSum > 0) buildSummaryBillRow('Selected Standard Amenities', '₹$amenitiesSum'),
                            if (manualAmenitiesSum > 0) buildSummaryBillRow('Custom Manual Amenities', '₹$manualAmenitiesSum'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6.0),
                              child: Divider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('₹$totalInvoice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            if (guestNameCtrl.text.isEmpty || guestPhoneCtrl.text.isEmpty || guestIdCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill out Name, Phone Number, and Address')),
                              );
                              return;
                            }

                            final hasOverlap = pmsState.bookings.any((b) {
                              if (b.roomId != selectedRoom.id || b.status == 'Completed') return false;
                              return b.checkInDate.isBefore(checkOutDate) && b.checkOutDate.isAfter(checkInDate);
                            });

                            if (hasOverlap) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.error_outline, color: AppColors.error),
                                      SizedBox(width: 8),
                                      Text('Already Booked'),
                                    ],
                                  ),
                                  content: Text('Room ${selectedRoom.roomNumber} is already booked for the selected dates. Please select another room or change dates.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            final newBooking = BookingModel(
                              id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
                              resortId: selectedResort.id,
                              roomId: selectedRoom.id,
                              roomNumber: selectedRoom.roomNumber,
                              guestName: guestNameCtrl.text,
                              guestPhone: guestPhoneCtrl.text,
                              guestIdProof: selectedIdProof,
                              guestIdNumber: guestIdCtrl.text,
                              bookingSource: selectedSource,
                              checkInDate: checkInDate,
                              checkOutDate: checkOutDate,
                              status: 'Upcoming',
                              depositPaid: double.tryParse(depositCtrl.text) ?? 0.0,
                              basePriceSum: basePriceSum,
                              weekendSurcharge: weekendSum,
                              seasonSurcharge: seasonSum,
                              holidaySurcharge: holidaySum,
                              extraBedCharge: extraBedSum,
                              amenitiesCharge: amenitiesSum + manualAmenitiesSum,
                              totalSum: totalInvoice,
                            );

                            pmsNotifier.createBooking(newBooking);
                            Navigator.pop(sheetContext); // Close sheet
                            
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Booking Successful'),
                                  ],
                                ),
                                content: Text('Room ${selectedRoom.roomNumber} has been booked successfully for ${guestNameCtrl.text}!'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Confirm Booking & Check-In'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          },
        );
      },
    );
}
