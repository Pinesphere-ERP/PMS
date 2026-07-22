import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/pms_provider.dart';
import '../../../../../core/theme/app_colors.dart';

Future<void> _pickImage(StateSetter setDialogState, List<String> uploadedImages) async {
  final ImagePicker picker = ImagePicker();
  try {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setDialogState(() {
        uploadedImages.add(pickedFile.path);
      });
    }
  } catch (e) {
    // Fail silently
  }
}

void showEditRoomSheet(BuildContext context, WidgetRef ref, RoomModel room) {
  final roomNumCtrl = TextEditingController(text: room.roomNumber);
  final typeCtrl = TextEditingController(text: room.type);
  final priceCtrl = TextEditingController(text: room.price.toStringAsFixed(0));
  final descriptionCtrl = TextEditingController(text: room.description);
  
  // Pricing rule controls
  final seasonCtrl = TextEditingController(text: room.seasonPrice.toStringAsFixed(0));
  final weekendCtrl = TextEditingController(text: room.weekendPrice.toStringAsFixed(0));
  final holidayCtrl = TextEditingController(text: room.holidayPrice.toStringAsFixed(0));
  final extraBedCtrl = TextEditingController(text: room.extraBedPrice.toStringAsFixed(0));

  // Room status default
  String initialStatus = room.status;

  // Dynamic amenities list inside dialog
  final List<Map<String, dynamic>> dialogAmenities = List.from(room.amenities);

  // Selected photo gallery paths
  final List<String> uploadedImages = List.from(room.images);

  final nameNewAmenityCtrl = TextEditingController();
  final priceNewAmenityCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
          final double safeAreaBottom = MediaQuery.of(context).padding.bottom;
          return Container(
            padding: EdgeInsets.only(bottom: keyboardPadding),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + safeAreaBottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Room Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: roomNumCtrl,
                            decoration: const InputDecoration(labelText: 'Room Number (e.g. 105)', contentPadding: EdgeInsets.zero),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: typeCtrl,
                            decoration: const InputDecoration(labelText: 'Room Type (e.g. Deluxe Suite)', contentPadding: EdgeInsets.zero),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: initialStatus,
                            decoration: const InputDecoration(labelText: 'Initial Status', contentPadding: EdgeInsets.zero),
                            items: ['Vacant', 'Occupied', 'Maintenance', 'Cleaning'].map((status) {
                              return DropdownMenuItem(value: status, child: Text(status));
                            }).toList(),
                            onChanged: (val) => setDialogState(() => initialStatus = val ?? 'Vacant'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descriptionCtrl,
                            decoration: const InputDecoration(labelText: 'Room Description', contentPadding: EdgeInsets.zero),
                            maxLines: 2,
                          ),
                          
                          const SizedBox(height: 16),
                          const Text('Configure Pricing Models (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Base Price / Night', contentPadding: EdgeInsets.zero),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: extraBedCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Extra Bed Cost', contentPadding: EdgeInsets.zero),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: weekendCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Weekend Surcharge', contentPadding: EdgeInsets.zero),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: seasonCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Season Surcharge', contentPadding: EdgeInsets.zero),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: holidayCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Holiday Surcharge', contentPadding: EdgeInsets.zero),
                          ),

                          const SizedBox(height: 20),
                          const Text('Room Custom Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                          const SizedBox(height: 6),
                          
                          // List current configured amenities
                          Column(
                            children: dialogAmenities.map((amenity) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('- ${amenity['name']} (₹${amenity['price']})', style: const TextStyle(fontSize: 11)),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 14, color: AppColors.error),
                                    onPressed: () {
                                      setDialogState(() {
                                        dialogAmenities.remove(amenity);
                                      });
                                    },
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 4),
                          
                          // Add new custom amenity form inline
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: nameNewAmenityCtrl,
                                  decoration: const InputDecoration(hintText: 'New amenity name...', contentPadding: EdgeInsets.zero),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: priceNewAmenityCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Cost (₹)', contentPadding: EdgeInsets.zero),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_box, color: AppColors.primary),
                                onPressed: () {
                                  if (nameNewAmenityCtrl.text.isNotEmpty && priceNewAmenityCtrl.text.isNotEmpty) {
                                    setDialogState(() {
                                      dialogAmenities.add({
                                        'name': nameNewAmenityCtrl.text,
                                        'price': double.tryParse(priceNewAmenityCtrl.text) ?? 10.0,
                                      });
                                      nameNewAmenityCtrl.clear();
                                      priceNewAmenityCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          Text(
                            'Room Photo Gallery (${uploadedImages.length}/5)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.outline),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(5, (index) {
                                final hasImage = index < uploadedImages.length;
                                final isNextSlot = index == uploadedImages.length;

                                if (hasImage) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: (kIsWeb || uploadedImages[index].startsWith('http') || uploadedImages[index].startsWith('blob:'))
                                                ? Image.network(
                                                    uploadedImages[index], 
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      color: AppColors.surfaceContainerHigh,
                                                      child: const Icon(Icons.broken_image_outlined, size: 24, color: AppColors.outline),
                                                    ),
                                                  )
                                                : Image.file(
                                                    File(uploadedImages[index]), 
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      color: AppColors.surfaceContainerHigh,
                                                      child: const Icon(Icons.broken_image_outlined, size: 24, color: AppColors.outline),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              setDialogState(() {
                                                uploadedImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, size: 10, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (isNextSlot) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () => _pickImage(setDialogState, uploadedImages),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.outlineVariant, width: 1.2),
                                        ),
                                        child: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.outline),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                                    ),
                                  );
                                }
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (roomNumCtrl.text.isEmpty) return;

                          final finalImages = uploadedImages.isEmpty
                              ? ['https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80']
                              : uploadedImages;

                          final updatedRoom = RoomModel(
                            id: room.id,
                            roomNumber: roomNumCtrl.text,
                            type: typeCtrl.text,
                            price: double.tryParse(priceCtrl.text) ?? 100.0,
                            seasonPrice: double.tryParse(seasonCtrl.text) ?? 30.0,
                            weekendPrice: double.tryParse(weekendCtrl.text) ?? 15.0,
                            holidayPrice: double.tryParse(holidayCtrl.text) ?? 40.0,
                            extraBedPrice: double.tryParse(extraBedCtrl.text) ?? 10.0,
                            amenities: List.from(dialogAmenities),
                            status: initialStatus,
                            resortId: room.resortId,
                            images: finalImages,
                            description: descriptionCtrl.text,
                          );

                          await ref.read(pmsProvider.notifier).updateRoomDetails(room.id, updatedRoom);
                          if (context.mounted) {
                            Navigator.pop(context); // Close sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Room ${roomNumCtrl.text} updated successfully!')),
                            );
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
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
