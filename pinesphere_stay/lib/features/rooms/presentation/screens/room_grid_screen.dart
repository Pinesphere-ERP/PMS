import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/pms_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../../bookings/presentation/screens/create_booking_sheet.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../core/auth/session_context.dart';
import '../../../../core/permissions/user_role.dart';

class RoomGridScreen extends ConsumerStatefulWidget {
  const RoomGridScreen({super.key});

  @override
  ConsumerState<RoomGridScreen> createState() => _RoomGridScreenState();
}

class _RoomGridScreenState extends ConsumerState<RoomGridScreen> {
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
    final authState = ref.watch(authProvider);
    final role = authState.maybeWhen(authenticated: (u) => u.role, orElse: () => UserRole.reception);
    final canAddEdit = role == UserRole.superAdmin || role == UserRole.owner || role == UserRole.manager;
    final isReceptionist = !canAddEdit;

    final sessionContext = ref.watch(sessionContextProvider);
    final userPropertyId = authState.maybeWhen(authenticated: (u) => u.propertyId, orElse: () => null);

    ref.read(pmsProvider.notifier).autoVacateExpiredBookings();
    final pmsState = ref.watch(pmsProvider);

    String activePropertyId = sessionContext.activePropertyId ?? userPropertyId ?? '';
    if (activePropertyId.isEmpty || activePropertyId == 'default') {
      if (pmsState.resorts.isNotEmpty) {
        activePropertyId = pmsState.resorts.first.id;
      }
    }

    final activePropertyName = sessionContext.activeProperty?.propertyName ??
        (pmsState.resorts.isNotEmpty ? pmsState.resorts.first.name : 'Property');

    final rooms = pmsState.rooms.where((r) {
      if (activePropertyId.isEmpty || activePropertyId == 'default') return true;
      final rid = r.resortId.toString().trim().toLowerCase();
      final target = activePropertyId.toString().trim().toLowerCase();
      return rid.isEmpty || rid == target || rid.contains(target) || target.contains(rid);
    }).toList();

    // Filter rooms
    final filteredRooms = rooms.where((room) {
      if (_activeFilter == 'All') return true;
      return room.status.toLowerCase() == _activeFilter.toLowerCase();
    }).toList();

    // Counts
    final vacantCount = rooms.where((r) => r.status.toLowerCase() == 'vacant').length;
    final occupiedCount = rooms.where((r) => r.status.toLowerCase() == 'occupied').length;
    final maintenanceCount = rooms.where((r) => r.status.toLowerCase() == 'maintenance').length;
    final cleaningCount = rooms.where((r) => r.status.toLowerCase() == 'cleaning').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PineBackground(
        child: CustomScrollView(
          slivers: [
          // Banner Sliver AppBar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  _showGlobalResortShareModal(context, activePropertyName, activePropertyId, rooms);
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                activePropertyName,
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
                  const SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black54,
                            Colors.black26,
                            Colors.transparent,
                            Colors.black87,
                          ],
                        ),
                      ),
                    ),
                  ),
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
              child: PineCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        const Text('Active Property', style: TextStyle(color: AppColors.outline, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    // Responsive wrapping counts layout
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatBadge(Icons.check_circle_outline, '$vacantCount Vacant', AppColors.secondaryContainer, AppColors.onSecondaryContainer),
                        _buildStatBadge(Icons.hotel, '$occupiedCount Occupied', AppColors.errorContainer, AppColors.onErrorContainer),
                        _buildStatBadge(Icons.build_outlined, '$maintenanceCount Maintenance', Colors.orange.withValues(alpha: 0.1), Colors.orange),
                        _buildStatBadge(Icons.cleaning_services_outlined, '$cleaningCount Housekeeping', Colors.teal.withValues(alpha: 0.1), Colors.teal),
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
                children: ['All', 'Vacant', 'Occupied', 'Maintenance', 'Cleaning', 'Bookings'].map((filter) {
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

          // Rooms grid / Bookings logs
          if (_activeFilter == 'Bookings')
            _buildBookingsLogsList(context, pmsState, rooms, ref)
          else if (filteredRooms.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text('No rooms in selected status', style: TextStyle(color: AppColors.outline)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.55,
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
      ),
      floatingActionButton: isReceptionist
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddRoomDialog(context, ref),
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
        mainAxisSize: MainAxisSize.min,
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
      onTap: () => _showRoomActionsSheet(context, room),
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
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => _showEditRoomDialog(context, room),
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
        ],
      ),
    );
  }


  Widget _buildSummaryBillRow(String label, String value) {
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
                      
                      // Detailed Booking Invoice Breakdown Card
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
                            _buildSummaryBillRow('Base Stay Charges:', '₹${booking.basePriceSum.toStringAsFixed(0)}'),
                            if (booking.weekendSurcharge > 0) _buildSummaryBillRow('Weekend Surcharges:', '+₹${booking.weekendSurcharge.toStringAsFixed(0)}'),
                            if (booking.seasonSurcharge > 0) _buildSummaryBillRow('Seasonal Surcharges:', '+₹${booking.seasonSurcharge.toStringAsFixed(0)}'),
                            if (booking.holidaySurcharge > 0) _buildSummaryBillRow('Holiday Surcharges:', '+₹${booking.holidaySurcharge.toStringAsFixed(0)}'),
                            if (booking.extraBedCharge > 0) _buildSummaryBillRow('Extra Bed Surcharges:', '+₹${booking.extraBedCharge.toStringAsFixed(0)}'),
                            if (booking.amenitiesCharge > 0) _buildSummaryBillRow('Amenities Surcharges:', '+₹${booking.amenitiesCharge.toStringAsFixed(0)}'),
                            const Divider(height: 12),
                            _buildSummaryBillRow('Total Reservation Price:', '₹${booking.totalSum.toStringAsFixed(0)}'),
                            _buildSummaryBillRow('Advance Deposit Paid:', '-₹${booking.depositPaid.toStringAsFixed(0)}'),
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

  void _showAddRoomDialog(BuildContext context, WidgetRef ref) {
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
  void _showEditRoomDialog(BuildContext context, RoomModel room) {
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

  void _showRoomActionsSheet(BuildContext context, RoomModel room) {
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
                                _showEditRoomDialog(context, liveRoom); // Open edit dialog
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
                          _showBookingDetailsSheet(context, activeBooking!, liveRoom);
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

  Widget _buildBookingsLogsList(BuildContext context, PmsState pmsState, List<RoomModel> rooms, WidgetRef ref) {
    final sessionContext = ref.read(sessionContextProvider);
    final activePropertyId = sessionContext.activePropertyId ?? 'default';

    final resortBookings = pmsState.bookings
        .where((b) => b.resortId == activePropertyId)
        .toList()
        .reversed
        .toList();

    if (resortBookings.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: Text('No bookings logged yet.', style: TextStyle(color: AppColors.outline)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final booking = resortBookings[index];
            final room = rooms.firstWhere(
              (r) => r.id == booking.roomId,
              orElse: () => RoomModel(
                id: '',
                roomNumber: booking.roomNumber,
                type: 'Unknown Type',
                price: 0,
                seasonPrice: 0,
                weekendPrice: 0,
                holidayPrice: 0,
                extraBedPrice: 0,
                amenities: [],
                status: '',
                resortId: '',
                images: [],
              ),
            );

            final isActive = booking.status == 'Active';
            final isManual = booking.guestName == 'Manual Occupancy Override';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: PineCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Room ${booking.roomNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(room.type, style: const TextStyle(fontSize: 12, color: AppColors.outline)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isManual ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1))
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? (isManual ? 'MANUAL' : 'ACTIVE') : 'COMPLETED',
                            style: TextStyle(
                              color: isActive ? (isManual ? Colors.orange : Colors.green) : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      isManual ? 'Manual Occupancy' : 'Guest: ${booking.guestName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (!isManual) const SizedBox(height: 2),
                    if (!isManual)
                      Text(
                        booking.guestIdProof == 'Address'
                            ? 'Phone: ${booking.guestPhone} | Address: ${booking.guestIdNumber}'
                            : 'Phone: ${booking.guestPhone} | ID: ${booking.guestIdProof} (${booking.guestIdNumber})',
                        style: const TextStyle(fontSize: 11, color: AppColors.outline),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-in: ${_getMonth(booking.checkInDate)} ${booking.checkInDate.day}',
                              style: const TextStyle(fontSize: 11, color: AppColors.outline),
                            ),
                            Text(
                              'Check-out: ${_getMonth(booking.checkOutDate)} ${booking.checkOutDate.day}',
                              style: const TextStyle(fontSize: 11, color: AppColors.outline),
                            ),
                          ],
                        ),
                        Text(
                          '₹${booking.totalSum.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: resortBookings.length,
        ),
      ),
    );
  }

  String _getMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  void _showGlobalResortShareModal(BuildContext context, String resortName, String resortId, List<dynamic> rooms) {
    final location = 'Main Property';

    final vacantRooms = rooms.where((r) => r.status.toString().toLowerCase() == 'vacant').toList();
    final listToShare = vacantRooms.isNotEmpty ? vacantRooms : rooms;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🏡 *$resortName* - Available Rooms Catalog');
    buffer.writeln('📍 Location: $location\n');
    buffer.writeln('Hello! Here are the current available rooms open for booking:\n');

    for (final r in listToShare) {
      final cleanType = r.type.toString().replaceAll('|', ' ');
      buffer.writeln('• *Room ${r.roomNumber}* - $cleanType');
      buffer.writeln('  Price: ₹${r.price.toStringAsFixed(0)} / night');
      buffer.writeln('  Status: ${r.status}');
      if (r.amenities != null && r.amenities.isNotEmpty) {
        final amenitiesList = (r.amenities as List).map((a) => a['name']?.toString() ?? a.toString()).take(3).join(', ');
        buffer.writeln('  Amenities: $amenitiesList');
      }
      buffer.writeln('');
    }

    const portalBaseUrl = String.fromEnvironment('PORTAL_URL', defaultValue: 'http://localhost:3000');
    final portalUrl = '$portalBaseUrl/guest-portal?property_id=$resortId';

    buffer.writeln('🔗 View photos & book online: $portalUrl');
    buffer.writeln('\nContact receptionist to complete your booking!');

    final catalogText = buffer.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Global Room Share',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${listToShare.length} room(s) available at $resortName',
                            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      catalogText,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('Share via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: catalogText));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Room catalog copied to clipboard! Ready to paste & send on WhatsApp!'),
                        backgroundColor: Color(0xFF25D366),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Catalog Text & Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: catalogText));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catalog text & guest portal link copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
