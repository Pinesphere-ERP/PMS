import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pms_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/auth/session_context.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

void showAddRoomSheet(BuildContext context, WidgetRef ref) {
  final sessionContext = ref.read(sessionContextProvider);
  final authState = ref.read(authProvider);
  final pmsState = ref.read(pmsProvider);

  final userPropertyId = authState.maybeWhen(authenticated: (u) => u.propertyId, orElse: () => null);
  String targetPropertyId = sessionContext.activePropertyId ?? userPropertyId ?? '';
  if (targetPropertyId.isEmpty || targetPropertyId == 'default') {
    if (pmsState.resorts.isNotEmpty) {
      targetPropertyId = pmsState.resorts.first.id;
    }
  }

  final activePropertyName = sessionContext.activeProperty?.propertyName ??
      (pmsState.resorts.isNotEmpty ? pmsState.resorts.first.name : 'Property');

  final roomNumCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  
  String initialStatus = 'Vacant';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add New Room',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: roomNumCtrl,
                          decoration: InputDecoration(
                            labelText: 'Room Number',
                            prefixIcon: const Icon(Icons.tag),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: initialStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['Vacant', 'Occupied', 'Maintenance', 'Cleaning'].map((status) {
                            return DropdownMenuItem(value: status, child: Text(status));
                          }).toList(),
                          onChanged: (val) => setDialogState(() => initialStatus = val ?? 'Vacant'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: typeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Room Type (e.g. Deluxe Suite)',
                      prefixIcon: const Icon(Icons.bed),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Base Price / Night (₹)',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (roomNumCtrl.text.isEmpty || typeCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields')),
                        );
                        return;
                      }

                      final newRoom = RoomModel(
                        id: 'room_${DateTime.now().millisecondsSinceEpoch}',
                        roomNumber: roomNumCtrl.text,
                        type: typeCtrl.text,
                        price: double.tryParse(priceCtrl.text) ?? 1000.0,
                        seasonPrice: 300.0, 
                        weekendPrice: 150.0, 
                        holidayPrice: 400.0, 
                        extraBedPrice: 100.0, 
                        amenities: [
                          {'name': 'Free WiFi', 'price': 0.0},
                          {'name': 'Air Conditioning', 'price': 0.0}
                        ],
                        status: initialStatus,
                        resortId: targetPropertyId,
                        images: ['https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80'],
                        description: descriptionCtrl.text,
                      );

                      ref.read(pmsProvider.notifier).addRoom(newRoom);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added Room ${roomNumCtrl.text} to $activePropertyName successfully!')),
                      );
                    },
                    child: const Text('Add Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
