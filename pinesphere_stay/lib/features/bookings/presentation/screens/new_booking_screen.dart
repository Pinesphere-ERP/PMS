import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class NewBookingScreen extends ConsumerStatefulWidget {
  const NewBookingScreen({super.key});

  @override
  ConsumerState<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends ConsumerState<NewBookingScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Active', 'Completed'

  String _getMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Automatically check and vacate expired bookings
    ref.read(pmsProvider.notifier).autoVacateExpiredBookings();

    final pmsState = ref.watch(pmsProvider);
    final bookings = pmsState.bookings;
    final resorts = pmsState.resorts;
    final rooms = pmsState.rooms;

    // Filter bookings based on search query and status filter
    final filteredBookings = bookings.where((booking) {
      final matchesStatus = _statusFilter == 'All' || booking.status == _statusFilter;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = booking.guestName.toLowerCase().contains(query) ||
                            booking.roomNumber.toLowerCase().contains(query) ||
                            booking.guestPhone.toLowerCase().contains(query) ||
                            booking.bookingSource.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList().reversed.toList(); // Newest bookings first

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Logs', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header Section
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search bookings by guest, room, phone...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 10),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: ['All', 'Active', 'Completed'].map((status) {
                      final isSelected = _statusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _statusFilter = status;
                            });
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Bookings List View
          Expanded(
            child: filteredBookings.isEmpty
                ? const Center(
                    child: Text(
                      'No matching reservation logs found.',
                      style: TextStyle(color: AppColors.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      
                      // Find matching resort name
                      final resort = resorts.firstWhere(
                        (r) => r.id == booking.resortId,
                        orElse: () => ResortModel(id: '', name: 'Unknown Resort', image: '', location: ''),
                      );

                      // Find matching room details
                      final room = rooms.firstWhere(
                        (r) => r.id == booking.roomId,
                        orElse: () => RoomModel(
                          id: '',
                          roomNumber: booking.roomNumber,
                          type: 'Deleted Room Type',
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
                        child: BentoCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Property & Status info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resort.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.outline),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Room ${booking.roomNumber}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              room.type,
                                              style: const TextStyle(fontSize: 11, color: AppColors.outline),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
                              const Divider(height: 20),

                              // Middle Section: Guest details
                              Text(
                                isManual ? 'Manual Occupancy' : 'Guest: ${booking.guestName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (!isManual) const SizedBox(height: 2),
                              if (!isManual)
                                Text(
                                  'Phone: ${booking.guestPhone} | ID: ${booking.guestIdProof} (${booking.guestIdNumber})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.outline),
                                ),
                              const SizedBox(height: 12),

                              // Bottom Row: Dates & Billing total
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${booking.totalSum.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                      ),
                                      if (booking.depositPaid > 0)
                                        Text(
                                          'Adv paid: ₹${booking.depositPaid.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 9, color: Colors.green),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
