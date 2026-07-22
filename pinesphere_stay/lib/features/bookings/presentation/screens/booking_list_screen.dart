import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../core/permissions/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  String _activeTab = 'All';
  String _searchQuery = '';
  String _activeSourceFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final pmsState = ref.watch(pmsProvider);
    final authState = ref.watch(authProvider);
    final role = authState.maybeWhen(authenticated: (u) => u.role, orElse: () => UserRole.reception);
    final isReceptionist = role == UserRole.reception;
    final userPropertyId = authState.maybeWhen(authenticated: (u) => u.propertyId, orElse: () => null);

    // Filter bookings by receptionist's assigned property
    var propertyBookings = pmsState.bookings;
    if (isReceptionist && userPropertyId != null && userPropertyId.isNotEmpty) {
      final matches = pmsState.bookings.where((b) {
        final rid = b.resortId.toString().trim().toLowerCase();
        final uid = userPropertyId.toString().trim().toLowerCase();
        return rid == uid || rid.contains(uid) || uid.contains(rid);
      }).toList();
      if (matches.isNotEmpty) {
        propertyBookings = matches;
      }
    }

    // Filter bookings based on search & dropdown selections
    final filteredBookings = propertyBookings.where((booking) {
      final matchesSearch = booking.guestName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          booking.roomNumber.contains(_searchQuery) ||
          booking.guestPhone.contains(_searchQuery);

      final matchesTab = _activeTab == 'All' ||
          (_activeTab == 'Active' && booking.status == 'Active') ||
          (_activeTab == 'Completed' && booking.status == 'Completed') ||
          (_activeTab == 'Upcoming' && booking.status == 'Upcoming');

      final matchesSource = _activeSourceFilter == 'All' || booking.bookingSource == _activeSourceFilter;

      return matchesSearch && matchesTab && matchesSource;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PineBackground(
        child: CustomScrollView(
          slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStats(propertyBookings),
                _buildSearchAndFilters(),
              ],
            ),
          ),
          filteredBookings.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 64, color: AppColors.outline),
                        SizedBox(height: 16),
                        Text(
                          'No bookings found',
                          style: TextStyle(color: AppColors.outline, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final booking = filteredBookings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildBookingCard(context, booking),
                        );
                      },
                      childCount: filteredBookings.length,
                    ),
                  ),
                ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _showCreateBookingSheet(context),
      //   backgroundColor: AppColors.primary,
      //   foregroundColor: AppColors.onPrimary,
      //   icon: const Icon(Icons.add_home_work_outlined),
      //   label: const Text('New Booking'),
      // ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.calendar_month, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            'Booking Management',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(List<BookingModel> bookings) {
    final activeCount = bookings.where((b) => b.status == 'Active').length;
    final completedCount = bookings.where((b) => b.status == 'Completed').length;
    final totalRevenue = bookings
        .where((b) => b.status == 'Completed')
        .fold<double>(0.0, (sum, b) => sum + b.depositPaid + b.damageBill + b.laundryBill + b.miniBarBill + b.restaurantBill);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: PineCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Stay', style: TextStyle(color: AppColors.outline, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('$activeCount Guests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PineCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Completed', style: TextStyle(color: AppColors.outline, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('$completedCount Stays', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PineCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Revenue', style: TextStyle(color: AppColors.outline, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('\$${totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final statusOptions = ['All', 'Active', 'Upcoming', 'Completed'];
    final modeOptions = ['All', 'Walk-in', 'Phone', 'WhatsApp', 'Online'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search guest name, room, phone...',
              prefixIcon: const Icon(Icons.search, color: AppColors.outline),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _activeTab,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                      items: statusOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'All' ? Icons.filter_alt : (value == 'Active' ? Icons.play_circle : (value == 'Upcoming' ? Icons.schedule : Icons.check_circle)),
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  value == 'All' ? 'Booking: All' : value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _activeTab = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _activeSourceFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
                      style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                      items: modeOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'All' ? Icons.devices : (value == 'Walk-in' ? Icons.directions_walk : (value == 'Phone' ? Icons.phone : (value == 'WhatsApp' ? Icons.chat : Icons.language))),
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  value == 'All' ? 'Mode: All' : value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _activeSourceFilter = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    Color statusColor;
    IconData sourceIcon;

    if (booking.status == 'Active') {
      statusColor = AppColors.primary;
    } else if (booking.status == 'Completed') {
      statusColor = AppColors.outline;
    } else {
      statusColor = Colors.orange;
    }

    switch (booking.bookingSource) {
      case 'WhatsApp':
        sourceIcon = Icons.chat_bubble_outline;
        break;
      case 'Phone':
        sourceIcon = Icons.phone_callback_outlined;
        break;
      case 'Online':
        sourceIcon = Icons.language_outlined;
        break;
      default:
        sourceIcon = Icons.directions_walk_outlined;
    }

    return PineCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _showBookingDetailsSheet(context, booking),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 20),
                const SizedBox(height: 4),
                Text(
                  booking.roomNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      booking.guestName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Icon(sourceIcon, size: 16, color: AppColors.outline),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.checkInDate.day} ${_getMonth(booking.checkInDate)} - ${booking.checkOutDate.day} ${_getMonth(booking.checkOutDate)}',
                  style: const TextStyle(color: AppColors.outline, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.guestPhone,
                  style: const TextStyle(color: AppColors.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${booking.depositPaid.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookingDetailsSheet(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room ${booking.roomNumber} Booking',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          Text('ID: ${booking.id}', style: const TextStyle(color: AppColors.outline, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          booking.status.toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Guest Details'),
                  _buildDetailRow('Guest Name', booking.guestName),
                  _buildDetailRow('Phone Number', booking.guestPhone),
                  booking.guestIdProof == 'Address'
                      ? _buildDetailRow('Address', booking.guestIdNumber)
                      : _buildDetailRow('ID Verified', '${booking.guestIdProof} - ${booking.guestIdNumber}'),
                  _buildDetailRow('Source', booking.bookingSource),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Stay Details'),
                  _buildDetailRow('Check In', '${booking.checkInDate.day} ${_getMonth(booking.checkInDate)} ${booking.checkInDate.year}'),
                  _buildDetailRow('Check Out', '${booking.checkOutDate.day} ${_getMonth(booking.checkOutDate)} ${booking.checkOutDate.year}'),
                  _buildDetailRow('Deposit Paid', '\$${booking.depositPaid}'),
                  const SizedBox(height: 16),
                  if (booking.status == 'Completed') ...[
                    _buildSectionHeader('Checkout Bill Details'),
                    _buildDetailRow('Damage Charges', '\$${booking.damageBill}'),
                    _buildDetailRow('Laundry Service', '\$${booking.laundryBill}'),
                    _buildDetailRow('Mini Bar add-ons', '\$${booking.miniBarBill}'),
                    _buildDetailRow('Restaurant Bills', '\$${booking.restaurantBill}'),
                    _buildDetailRow('Total Paid', '\$${booking.depositPaid + booking.damageBill + booking.laundryBill + booking.miniBarBill + booking.restaurantBill}', isBold: true),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionHeader('Verification & Documents'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Digital Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.outline)),
                        const SizedBox(height: 16),
                        Center(
                          child: Icon(Icons.gesture, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        const Center(
                          child: Text('Digitally signed on check-in', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: AppColors.outline)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (booking.status == 'Active')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCheckoutSheet(context, booking);
                      },
                      child: const Text('Start Checkout Flow'),
                    )
                  else
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCheckoutSheet(BuildContext context, BookingModel booking) {
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
                            decoration: InputDecoration(labelText: 'Restaurant Bill (\$)', border: const OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: laundryCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(labelText: 'Laundry Bill (\$)', border: const OutlineInputBorder()),
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
                            decoration: InputDecoration(labelText: 'Mini Bar (\$)', border: const OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: damageCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(labelText: 'Damage Charges (\$)', border: const OutlineInputBorder()),
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



  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.outline, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.outline, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
              color: isBold ? AppColors.primary : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }
}
