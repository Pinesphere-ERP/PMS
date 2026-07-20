import re

with open('lib/features/rooms/presentation/screens/room_grid_screen.dart', 'r') as f:
    content = f.read()

start_idx = content.find('  void _showAddRoomDialog(BuildContext context) {')
end_idx = content.find('  void _showEditRoomDialog(BuildContext context, RoomModel room) {')

if start_idx == -1 or end_idx == -1:
    print("Could not find start or end")
    exit(1)

new_code = """  void _showAddRoomDialog(BuildContext context) {
    final roomNumCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    
    String initialStatus = 'Vacant';
    final List<String> uploadedImages = [];

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
                            value: initialStatus,
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
                          resortId: widget.resort.id,
                          images: ['https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80'],
                          description: descriptionCtrl.text,
                        );

                        ref.read(pmsProvider.notifier).addRoom(newRoom);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added Room ${roomNumCtrl.text} to ${widget.resort.name} successfully!')),
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
"""

with open('lib/features/rooms/presentation/screens/room_grid_screen.dart', 'w') as f:
    f.write(content[:start_idx] + new_code + content[end_idx:])

print("Successfully replaced _showAddRoomDialog")
