import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/pms_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class RoomGridScreen extends ConsumerStatefulWidget {
  const RoomGridScreen({super.key});

  @override
  ConsumerState<RoomGridScreen> createState() => _RoomGridScreenState();
}

class _RoomGridScreenState extends ConsumerState<RoomGridScreen> {
  @override
  Widget build(BuildContext context) {
    final pmsState = ref.watch(pmsProvider);
    final resorts = pmsState.resorts;
    final rooms = pmsState.rooms;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final resort = resorts[index];
                  final resortRooms = rooms.where((r) => r.resortId == resort.id).toList();
                  
                  return BentoCard(
                    padding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResortRoomsDetailScreen(resort: resort),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(
                              resort.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: const Icon(Icons.broken_image, size: 32, color: AppColors.outline),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resort.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                resort.location,
                                style: const TextStyle(color: AppColors.outline, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${resortRooms.length} Rooms',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: resorts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => context.go('/dashboard'),
      ),
      title: Row(
        children: [
          const Icon(Icons.signal_wifi_off, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            'PineSphere Stay',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class ResortRoomsDetailScreen extends ConsumerStatefulWidget {
  final ResortModel resort;
  const ResortRoomsDetailScreen({super.key, required this.resort});

  @override
  ConsumerState<ResortRoomsDetailScreen> createState() => _ResortRoomsDetailScreenState();
}

class _ResortRoomsDetailScreenState extends ConsumerState<ResortRoomsDetailScreen> {
  String _activeFilter = 'All';

  Future<void> pickImage(StateSetter setDialogState, List<String> uploadedImages) async {
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

  @override
  Widget build(BuildContext context) {
    final pmsState = ref.watch(pmsProvider);
    final rooms = pmsState.rooms.where((r) => r.resortId == widget.resort.id).toList();

    // Filter rooms
    final filteredRooms = rooms.where((room) {
      if (_activeFilter == 'All') return true;
      return room.status.toLowerCase() == _activeFilter.toLowerCase();
    }).toList();

    // Counts
    final vacantCount = rooms.where((r) => r.status == 'Vacant').length;
    final occupiedCount = rooms.where((r) => r.status == 'Occupied').length;
    final cleaningCount = rooms.where((r) => r.status == 'Cleaning').length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // Banner Sliver AppBar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.resort.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(widget.resort.image, fit: BoxFit.cover),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resort Stats Dashboard Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BentoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(widget.resort.location, style: const TextStyle(color: AppColors.outline, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBadge(Icons.check_circle_outline, '$vacantCount Vacant', AppColors.secondaryContainer, AppColors.onSecondaryContainer),
                        _buildStatBadge(Icons.hotel, '$occupiedCount Occupied', AppColors.errorContainer, AppColors.onErrorContainer),
                        _buildStatBadge(Icons.cleaning_services, '$cleaningCount Cleaning', Colors.orange.withValues(alpha: 0.1), Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filters Tab Header
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Vacant', 'Occupied', 'Cleaning'].map((filter) {
                  final isSelected = _activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _activeFilter = filter;
                        });
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      checkmarkColor: AppColors.onPrimary,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Rooms grid
          filteredRooms.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Text('No rooms in selected status', style: TextStyle(color: AppColors.outline)),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final room = filteredRooms[index];
                        return _buildRoomCard(context, room);
                      },
                      childCount: filteredRooms.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoomDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor)),
        ],
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    Color edgeColor;
    Color chipBg;
    Color chipText;
    final pmsState = ref.read(pmsProvider);

    if (room.status == 'Occupied') {
      edgeColor = AppColors.error;
      chipBg = AppColors.errorContainer;
      chipText = AppColors.onErrorContainer;
    } else if (room.status == 'Vacant') {
      edgeColor = AppColors.primary;
      chipBg = AppColors.secondaryContainer;
      chipText = AppColors.onSecondaryContainer;
    } else {
      edgeColor = Colors.orange;
      chipBg = Colors.orange.withValues(alpha: 0.1);
      chipText = Colors.orange;
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
        ),
      );
    }

    return BentoCard(
      padding: const EdgeInsets.all(12),
      onTap: () {
        if (room.status == 'Vacant') {
          _showBookingSheet(context, room);
        } else if (room.status == 'Occupied' && activeBooking != null) {
          _showBookingDetailsSheet(context, activeBooking, room);
        } else if (room.status == 'Cleaning') {
          _showCleanRoomConfirm(context, room);
        }
      },
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 70,
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
                      room.status.toUpperCase(),
                      style: TextStyle(color: chipText, fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                room.type,
                style: const TextStyle(color: AppColors.outline, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '\$${room.price.toStringAsFixed(0)}/night',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11),
              ),
              const Spacer(),
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
              if (room.status == 'Cleaning')
                const Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 12, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'In progress...',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange, fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookingSheet(BuildContext context, RoomModel room) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final idProofCtrl = TextEditingController(text: 'Aadhaar Card');
    final idNumCtrl = TextEditingController();
    final depositCtrl = TextEditingController(text: '1000');
    String source = 'Walk-in';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Room ${room.roomNumber} - ${room.type}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Guest Name')),
                    const SizedBox(height: 12),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: idProofCtrl.text,
                            decoration: const InputDecoration(labelText: 'ID Proof'),
                            items: ['Aadhaar Card', 'Passport', 'Driving License', 'Voter ID'].map((proof) {
                              return DropdownMenuItem(value: proof, child: Text(proof));
                            }).toList(),
                            onChanged: (val) => idProofCtrl.text = val ?? idProofCtrl.text,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(controller: idNumCtrl, decoration: const InputDecoration(labelText: 'ID Number')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: source,
                            decoration: const InputDecoration(labelText: 'Booking Source'),
                            items: ['Walk-in', 'Phone', 'WhatsApp', 'Online'].map((src) {
                              return DropdownMenuItem(value: src, child: Text(src));
                            }).toList(),
                            onChanged: (val) => source = val ?? source,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(controller: depositCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance DepositPaid (\$)')),
                        ),
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
                          if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;

                          final newBooking = BookingModel(
                            id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
                            resortId: room.resortId,
                            roomId: room.id,
                            roomNumber: room.roomNumber,
                            guestName: nameCtrl.text,
                            guestPhone: phoneCtrl.text,
                            guestIdProof: idProofCtrl.text,
                            guestIdNumber: idNumCtrl.text,
                            bookingSource: source,
                            checkInDate: DateTime.now(),
                            checkOutDate: DateTime.now().add(const Duration(days: 2)),
                            status: 'Active',
                            depositPaid: double.tryParse(depositCtrl.text) ?? 1000.0,
                          );

                          ref.read(pmsProvider.notifier).createBooking(newBooking);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Room ${room.roomNumber} Booked Successfully!')),
                          );
                        },
                        child: const Text('Confirm Booking'),
                      ),
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

  void _showBookingDetailsSheet(BuildContext context, BookingModel booking, RoomModel room) {
    final damageCtrl = TextEditingController(text: '0');
    final laundryCtrl = TextEditingController(text: '0');
    final miniBarCtrl = TextEditingController(text: '0');
    final restaurantCtrl = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            double calcTotal() {
              final damage = double.tryParse(damageCtrl.text) ?? 0;
              final laundry = double.tryParse(laundryCtrl.text) ?? 0;
              final miniBar = double.tryParse(miniBarCtrl.text) ?? 0;
              final restaurant = double.tryParse(restaurantCtrl.text) ?? 0;
              return booking.depositPaid + damage + laundry + miniBar + restaurant;
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Checkout Bill Settlement',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text('Guest: ${booking.guestName} | Room ${booking.roomNumber}', style: const TextStyle(color: AppColors.outline)),
                    const Divider(height: 24),
                    const Text('Additional Incidentals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: restaurantCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(labelText: 'Restaurant (\$)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: laundryCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(labelText: 'Laundry (\$)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: miniBarCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(labelText: 'Mini Bar (\$)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: damageCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(labelText: 'Damage (\$)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Initial Deposit Paid:', style: TextStyle(color: AppColors.outline)),
                        Text('\$${booking.depositPaid}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Final Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('\$${calcTotal().toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                            SnackBar(content: Text('Checked out ${booking.guestName} successfully. Room is now in CLEANING.')),
                          );
                        },
                        child: const Text('Settle Bill & Complete Checkout'),
                      ),
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

  void _showCleanRoomConfirm(BuildContext context, RoomModel room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark Room ${room.roomNumber} Clean?'),
        content: const Text('Marking the room as clean will transition its status back to VACANT, making it available for new bookings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: () {
              ref.read(pmsProvider.notifier).markRoomClean(room.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Room ${room.roomNumber} is now VACANT and ready to book!')),
              );
            },
            child: const Text('Mark Clean'),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    final roomNumCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'Standard Room');
    final priceCtrl = TextEditingController(text: '100');
    final List<String> uploadedImages = [];

    Future<void> pickImage(StateSetter setDialogState, List<String> uploadedImages) async {
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Room to ${widget.resort.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: roomNumCtrl,
                      decoration: const InputDecoration(labelText: 'Room Number (e.g. 105)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: typeCtrl,
                      decoration: const InputDecoration(labelText: 'Room Type'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price per Night (\$)'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Room Images (${uploadedImages.length}/5)',
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
                                          ? Image.network(uploadedImages[index], fit: BoxFit.cover)
                                          : Image.file(File(uploadedImages[index]), fit: BoxFit.cover),
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
                                onTap: () => pickImage(setDialogState, uploadedImages),
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
                                  color: AppColors.surfaceContainerLow.withOpacity(0.4),
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
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  onPressed: () {
                    if (roomNumCtrl.text.isEmpty) return;

                    final finalImages = uploadedImages.isEmpty
                        ? ['https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80']
                        : uploadedImages;

                    final newRoom = RoomModel(
                      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
                      roomNumber: roomNumCtrl.text,
                      type: typeCtrl.text,
                      price: double.tryParse(priceCtrl.text) ?? 100,
                      status: 'Vacant',
                      resortId: widget.resort.id,
                      images: finalImages,
                    );

                    ref.read(pmsProvider.notifier).addRoom(newRoom);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added Room ${roomNumCtrl.text} to ${widget.resort.name} successfully with ${finalImages.length} images!')),
                    );
                  },
                  child: const Text('Add Room'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }
}
