import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pms_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../core/auth/session_context.dart';
import '../../../../core/permissions/user_role.dart';
import '../widgets/room_filter_tabs.dart';
import '../widgets/room_grid_view.dart';
import '../sheets/add_room_sheet.dart';

class RoomGridScreen extends ConsumerStatefulWidget {
  const RoomGridScreen({super.key});

  @override
  ConsumerState<RoomGridScreen> createState() => _RoomGridScreenState();
}

class _RoomGridScreenState extends ConsumerState<RoomGridScreen> {
  String _activeFilter = 'All';

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

    String activePropertyName = sessionContext.activeProperty?.propertyName ?? '';
    if (activePropertyName.isEmpty) {
      activePropertyName = pmsState.resorts.isNotEmpty ? pmsState.resorts.first.name : 'Property';
    }

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
// Removed leading back button as this is a top-level tab
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
              child: RoomFilterTabs(
                activeFilter: _activeFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _activeFilter = filter;
                  });
                },
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
              RoomGridView(rooms: filteredRooms),
          ],
        ),
      ),
      floatingActionButton: isReceptionist
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddRoomSheet(context, ref),
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

  String _getMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
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
    final portalUrl = '$portalBaseUrl/share/resort/$resortId';

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
