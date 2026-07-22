import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pms_provider.dart';
import '../../../../../core/theme/app_colors.dart';

void showCheckoutBillSheet(BuildContext context, WidgetRef ref, BookingModel booking, RoomModel room) {
  final damageCtrl = TextEditingController(text: '0');
  final laundryCtrl = TextEditingController(text: '0');
  final miniBarCtrl = TextEditingController(text: '0');
  final restaurantCtrl = TextEditingController(text: '0');

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

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          double calcIncidentals() {
            final damage = double.tryParse(damageCtrl.text) ?? 0;
            final laundry = double.tryParse(laundryCtrl.text) ?? 0;
            final miniBar = double.tryParse(miniBarCtrl.text) ?? 0;
            final restaurant = double.tryParse(restaurantCtrl.text) ?? 0;
            return damage + laundry + miniBar + restaurant;
          }

          double calcFinalPayable() {
            return booking.totalSum + calcIncidentals() - booking.depositPaid;
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Checkout Bill Settlement',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text('Guest: ${booking.guestName} | Room ${booking.roomNumber}', style: const TextStyle(color: AppColors.outline, fontSize: 13)),
                    const Divider(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INVOICE ITEMIZED BREAKDOWN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.outline)),
                          const SizedBox(height: 6),
                          buildSummaryBillRow('Base Stay Charges:', '₹${booking.basePriceSum.toStringAsFixed(0)}'),
                          if (booking.weekendSurcharge > 0) buildSummaryBillRow('Weekend Surcharges:', '+₹${booking.weekendSurcharge.toStringAsFixed(0)}'),
                          if (booking.seasonSurcharge > 0) buildSummaryBillRow('Seasonal Surcharges:', '+₹${booking.seasonSurcharge.toStringAsFixed(0)}'),
                          if (booking.holidaySurcharge > 0) buildSummaryBillRow('Holiday Surcharges:', '+₹${booking.holidaySurcharge.toStringAsFixed(0)}'),
                          if (booking.extraBedCharge > 0) buildSummaryBillRow('Extra Bed Surcharges:', '+₹${booking.extraBedCharge.toStringAsFixed(0)}'),
                          if (booking.amenitiesCharge > 0) buildSummaryBillRow('Amenities Surcharges:', '+₹${booking.amenitiesCharge.toStringAsFixed(0)}'),
                          const Divider(height: 12),
                          buildSummaryBillRow('Total Reservation Price:', '₹${booking.totalSum.toStringAsFixed(0)}'),
                          buildSummaryBillRow('Advance Deposit Paid:', '-₹${booking.depositPaid.toStringAsFixed(0)}'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text('Add Incidentals at Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: restaurantCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(labelText: 'Restaurant (₹)', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: laundryCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(labelText: 'Laundry (₹)', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: miniBarCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(labelText: 'Mini Bar (₹)', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: damageCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(labelText: 'Damage (₹)', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Net Incidentals:', style: TextStyle(color: AppColors.outline, fontSize: 13)),
                        Text('₹${calcIncidentals().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net Final Payable:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('₹${calcFinalPayable().toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
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
                          ref.read(pmsProvider.notifier).checkOut(
                                booking.id,
                                damage: double.tryParse(damageCtrl.text) ?? 0,
                                laundry: double.tryParse(laundryCtrl.text) ?? 0,
                                miniBar: double.tryParse(miniBarCtrl.text) ?? 0,
                                restaurant: double.tryParse(restaurantCtrl.text) ?? 0,
                              );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Checked out ${booking.guestName} successfully. Room is now in MAINTENANCE.')),
                          );
                        },
                        child: const Text('Settle Bill & Complete Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
