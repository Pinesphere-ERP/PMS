import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/security/permission_engine.dart';
import '../../../../core/presentation/widgets/access_restricted_view.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/auth_notifier.dart';
import '../providers/checkout_provider.dart';

class CheckOutScreen extends ConsumerStatefulWidget {
  const CheckOutScreen({super.key});

  @override
  ConsumerState<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends ConsumerState<CheckOutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  // ignore: unused_field
  final DateFormat _timeFormat = DateFormat('hh:mm a');


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      ref.read(checkOutProvider.notifier).getPendingCheckOuts(ref.read(authProvider).whenOrNull(authenticated: (u) => u.propertyId) ?? '');
    } else {
      ref.read(checkOutProvider.notifier).getTodaysCheckOuts(ref.read(authProvider).whenOrNull(authenticated: (u) => u.propertyId) ?? '');
    }
  }

  void _loadInitialData() {
    ref.read(checkOutProvider.notifier).getPendingCheckOuts(ref.read(authProvider).whenOrNull(authenticated: (u) => u.propertyId) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );
    final role = user?.role ?? UserRole.guest;

    final canView = PermissionEngine.hasPermission(role, PermissionModule.checkIn, PermissionAction.view);
    final canDigitalCheckIn = PermissionEngine.hasPermission(role, PermissionModule.checkIn, PermissionAction.digitalCheckIn);
    final canFull = PermissionEngine.hasPermission(role, PermissionModule.checkIn, PermissionAction.full);

    if (!canView && !canDigitalCheckIn && !canFull) {
      return const AccessRestrictedView(
        title: 'Checkout Restricted',
        message: 'Your role does not permit access to the Checkout module.',
      );
    }

    final isViewOnly = !canFull && !canDigitalCheckIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Check-Out'),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending Checkouts'),
            Tab(text: "Today's Checkouts"),
          ],
        ),
      ),
      body: Column(
        children: [
          if (isViewOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber.withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'View-Only Mode',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingCheckoutsTab(isViewOnly),
                _buildTodaysCheckoutsTab(isViewOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PENDING CHECKOUTS TAB ────────────────────────────────────────────────

  Widget _buildPendingCheckoutsTab(bool isViewOnly) {
    final state = ref.watch(checkOutProvider);
    return state.when(
      initial: () => const EmptyStateWidget(
        icon: Icons.domain,
        title: 'Select Property',
        message: 'Please select a property to view pending checkouts.',
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (msg) => _buildErrorView(msg, () => ref.read(checkOutProvider.notifier).getPendingCheckOuts(ref.read(authProvider).whenOrNull(authenticated: (u) => u.propertyId) ?? '')),
      success: (_, __) => const EmptyStateWidget(
        icon: Icons.check_circle,
        title: 'Action Completed',
        message: 'The checkout action was completed successfully.',
      ),
      loadedPendingCheckouts: (checkouts) => _buildPendingCheckoutsList(checkouts, isViewOnly),
      loadedBilling: (_) => const SizedBox.shrink(),
      loadedTodaysCheckouts: (_) => const SizedBox.shrink(),
      loadedDetail: (_) => const SizedBox.shrink(),
    );
  }

  Widget _buildPendingCheckoutsList(List<Map<String, dynamic>> checkouts, bool isViewOnly) {
    if (checkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No pending checkouts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'All guests have been checked out.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(checkOutProvider.notifier).getPendingCheckOuts(ref.read(authProvider).whenOrNull(authenticated: (u) => u.propertyId) ?? ''),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: checkouts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildPendingCheckoutCard(checkouts[index], isViewOnly),
      ),
    );
  }

  Widget _buildPendingCheckoutCard(Map<String, dynamic> checkout, bool isViewOnly) {
    final guestName = checkout['guest_name']?.toString() ?? checkout['guestName'] ?? 'Unknown Guest';
    final roomNumber = checkout['room_number']?.toString() ?? checkout['roomNumber'] ?? '-';
    final checkinDate = checkout['checkin_date']?.toString() ?? checkout['checkinDate'] ?? '';
    final nights = checkout['nights_stayed']?.toString() ?? checkout['nightsStayed'] ?? '-';
    final amountDue = checkout['amount_due']?.toString() ?? checkout['totalBillAmount'] ?? '0.00';

    return BentoCard(
      onTap: () => _openBillingSheet(checkout, isViewOnly),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Room $roomNumber',
                  style: const TextStyle(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            guestName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.outline),
              const SizedBox(width: 4),
              Text(
                'Check-in: $checkinDate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(Icons.nightlight_round, '$nights nights'),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.attach_money, '₹$amountDue'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ─── TODAY'S CHECKOUTS TAB ────────────────────────────────────────────────

  Widget _buildTodaysCheckoutsTab(bool isViewOnly) {
    final state = ref.watch(checkOutProvider);
    return state.when(
      initial: () => const EmptyStateWidget(
        icon: Icons.domain,
        title: 'Select Property',
        message: 'Please select a property to view today\'s checkouts.',
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (msg) => _buildErrorView(msg, () => ref.read(checkOutProvider.notifier).getTodaysCheckOuts(ref.read(authProvider).whenOrNull(authenticated: (u) => u.propertyId) ?? '')),
      success: (_, __) => const EmptyStateWidget(
        icon: Icons.check_circle,
        title: 'Action Completed',
        message: 'The checkout action was completed successfully.',
      ),
      loadedTodaysCheckouts: (checkouts) => _buildTodaysCheckoutsTable(checkouts, isViewOnly),
      loadedPendingCheckouts: (_) => const SizedBox.shrink(),
      loadedBilling: (_) => const SizedBox.shrink(),
      loadedDetail: (_) => const SizedBox.shrink(),
    );
  }

  Widget _buildTodaysCheckoutsTable(List<Map<String, dynamic>> checkouts, bool isViewOnly) {
    if (checkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No checkouts today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'No guests have checked out today yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(checkOutProvider.notifier).getTodaysCheckOuts(ref.read(authProvider).whenOrNull(authenticated: (u) => u.propertyId) ?? ''),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceContainerLowest),
            columns: const [
              DataColumn(label: Text('Room', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Guest', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Checkout Time', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: checkouts.map((co) {
              final roomNumber = co['room_number']?.toString() ?? co['roomNumber'] ?? '-';
              final guestName = co['guest_name']?.toString() ?? co['guestName'] ?? '-';
              final checkoutTime = co['checkout_time']?.toString() ?? co['checkoutTime'] ?? '-';
              final totalAmount = co['total_amount']?.toString() ?? co['totalAmount'] ?? '0.00';
              final paymentStatus = co['payment_status']?.toString() ?? co['paymentStatus'] ?? 'pending';

              return DataRow(cells: [
                DataCell(Text(roomNumber)),
                DataCell(Text(guestName)),
                DataCell(Text(checkoutTime)),
                DataCell(Text('₹$totalAmount')),
                DataCell(_buildPaymentStatusChip(paymentStatus)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'paid':
        chipColor = Colors.green;
        break;
      case 'partial':
        chipColor = Colors.orange;
        break;
      case 'refunded':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: chipColor),
      ),
    );
  }

  // ─── ERROR VIEW ───────────────────────────────────────────────────────────

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BILLING SHEET ────────────────────────────────────────────────────────

  void _openBillingSheet(Map<String, dynamic> checkout, bool isViewOnly) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BillingSheet(
        checkout: checkout,
        dateFormat: _dateFormat,
        ref: ref,
        isViewOnly: isViewOnly,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BILLING SHEET WIDGET
// ═════════════════════════════════════════════════════════════════════════════

class _BillingSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> checkout;
  final DateFormat dateFormat;
  final WidgetRef ref;
  final bool isViewOnly;

  const _BillingSheet({
    required this.checkout,
    required this.dateFormat,
    required this.ref,
    required this.isViewOnly,
  });

  @override
  ConsumerState<_BillingSheet> createState() => _BillingSheetState();
}

class _BillingSheetState extends ConsumerState<_BillingSheet> {
  // Section 2 – Charges
  late TextEditingController _roomChargesController;
  late TextEditingController _restaurantController;
  late TextEditingController _laundryController;
  late TextEditingController _miniBarController;
  late TextEditingController _damageController;
  late TextEditingController _miscController;

  // Section 3 – Adjustments
  late TextEditingController _discountController;
  late TextEditingController _gstController;

  // Section 5 – Checkout Options
  bool _keyReturned = false;
  bool _idReturned = false;
  late TextEditingController _remarksController;

  bool _isSubmitting = false;

  String get _guestName => widget.checkout['guest_name']?.toString() ?? widget.checkout['guestName'] ?? '-';
  String get _roomNumber => widget.checkout['room_number']?.toString() ?? widget.checkout['roomNumber'] ?? '-';
  String get _checkinDate => widget.checkout['checkin_date']?.toString() ?? widget.checkout['checkinDate'] ?? '-';
  String get _checkinId => widget.checkout['checkin_id']?.toString() ?? widget.checkout['checkinId'] ?? '';
  String get _bookingId => widget.checkout['booking_id']?.toString() ?? widget.checkout['bookingId'] ?? '';
  String get _roomId => widget.checkout['room_id']?.toString() ?? widget.checkout['roomId'] ?? '';
  String get _propertyId => widget.checkout['property_id']?.toString() ?? widget.checkout['propertyId'] ?? '';
  String get _staffId => widget.checkout['staff_id']?.toString() ?? widget.checkout['staffId'] ?? '';
  double get _advancePaid => double.tryParse(widget.checkout['advance_paid']?.toString() ?? widget.checkout['advancePaid']?.toString() ?? '0') ?? 0;
  int get _nights => int.tryParse(widget.checkout['nights_stayed']?.toString() ?? widget.checkout['nightsStayed']?.toString() ?? '0') ?? 0;
  String get _checkinDateFormatted {
    try {
      final raw = widget.checkout['checkin_date']?.toString() ?? widget.checkout['checkinDate'] ?? '';
      if (raw.isEmpty) return '-';
      final dt = DateTime.parse(raw);
      return widget.dateFormat.format(dt);
    } catch (_) {
      return _checkinDate;
    }
  }

  double get _totalCharges =>
      _parseDouble(_roomChargesController.text) +
      _parseDouble(_restaurantController.text) +
      _parseDouble(_laundryController.text) +
      _parseDouble(_miniBarController.text) +
      _parseDouble(_damageController.text) +
      _parseDouble(_miscController.text);

  double get _totalAmount => _totalCharges - _parseDouble(_discountController.text) + _parseDouble(_gstController.text);
  double get _remainingBalance => _totalAmount - _advancePaid;
  double get _refundAmount => _remainingBalance < 0 ? _remainingBalance.abs() : 0;

  @override
  void initState() {
    super.initState();
    final ratePerNight = double.tryParse(widget.checkout['rate_per_night']?.toString() ?? widget.checkout['ratePerNight']?.toString() ?? '0') ?? 0;
    final autoRoomCharges = ratePerNight * _nights;

    _roomChargesController = TextEditingController(text: autoRoomCharges > 0 ? autoRoomCharges.toStringAsFixed(2) : '');
    _restaurantController = TextEditingController(text: '0');
    _laundryController = TextEditingController(text: '0');
    _miniBarController = TextEditingController(text: '0');
    _damageController = TextEditingController(text: '0');
    _miscController = TextEditingController(text: '0');
    _discountController = TextEditingController(text: '0');
    _gstController = TextEditingController(text: '0');
    _remarksController = TextEditingController();
  }

  @override
  void dispose() {
    _roomChargesController.dispose();
    _restaurantController.dispose();
    _laundryController.dispose();
    _miniBarController.dispose();
    _damageController.dispose();
    _miscController.dispose();
    _discountController.dispose();
    _gstController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  double _parseDouble(String value) => double.tryParse(value) ?? 0;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildSheetHandle(),
          _buildSheetHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: viewInsets + 24),
              child: AbsorbPointer(
                absorbing: widget.isViewOnly,
                child: Column(
                  children: [
                    _buildSection1GuestSummary(),
                    _buildSection2Charges(),
                    _buildSection3Adjustments(),
                    _buildSection4PaymentSummary(),
                    _buildSection5CheckoutOptions(),
                    if (!widget.isViewOnly) _buildSection6Actions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout Billing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Room $_roomNumber  •  $_guestName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  // ─── SECTION 1: GUEST & STAY SUMMARY (read-only) ────────────────────────

  Widget _buildSection1GuestSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Guest & Stay Summary'),
            _buildReadOnlyRow('Guest Name', _guestName),
            _buildReadOnlyRow('Room Number', _roomNumber),
            _buildReadOnlyRow('Check-in Date', _checkinDateFormatted),
            _buildReadOnlyRow('Check-out Date', widget.dateFormat.format(DateTime.now())),
            _buildReadOnlyRow('Nights Stayed', '$_nights'),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 2: CHARGES (editable) ──────────────────────────────────────

  Widget _buildSection2Charges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Charges'),
            _buildChargeField('Room Charges', _roomChargesController),
            _buildChargeField('Restaurant Bills', _restaurantController),
            _buildChargeField('Laundry', _laundryController),
            _buildChargeField('Mini Bar', _miniBarController),
            _buildChargeField('Damage Charges', _damageController),
            _buildChargeField('Miscellaneous', _miscController),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 3: ADJUSTMENTS ─────────────────────────────────────────────

  Widget _buildSection3Adjustments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Adjustments'),
            _buildChargeField('Discount', _discountController),
            _buildChargeField('GST', _gstController),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Total',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.primaryContainer.withValues(alpha: 0.1),
              ),
              child: Text(
                '₹${_totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 4: PAYMENT SUMMARY (read-only) ────────────────────────────

  Widget _buildSection4PaymentSummary() {
    final isRefund = _refundAmount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Payment Summary'),
            _buildSummaryRow('Total Amount', '₹${_totalAmount.toStringAsFixed(2)}', isBold: true),
            _buildSummaryRow('Advance Paid', '₹${_advancePaid.toStringAsFixed(2)}'),
            const Divider(height: 20),
            _buildSummaryRow(
              isRefund ? 'Refund Amount' : 'Remaining Balance',
              '₹${isRefund ? _refundAmount.toStringAsFixed(2) : _remainingBalance.toStringAsFixed(2)}',
              isBold: true,
              valueColor: isRefund ? Colors.blue : (_remainingBalance > 0 ? AppColors.error : AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 5: CHECKOUT OPTIONS ────────────────────────────────────────

  Widget _buildSection5CheckoutOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Checkout Options'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Key Returned'),
              subtitle: Text(
                _keyReturned ? 'Key has been returned' : 'Key not yet returned',
                style: TextStyle(fontSize: 12, color: _keyReturned ? Colors.green : AppColors.onSurfaceVariant),
              ),
              value: _keyReturned,
              onChanged: (v) => setState(() => _keyReturned = v),
              activeThumbColor: AppColors.primary,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ID Returned'),
              subtitle: Text(
                _idReturned ? 'ID document has been returned' : 'ID document not yet returned',
                style: TextStyle(fontSize: 12, color: _idReturned ? Colors.green : AppColors.onSurfaceVariant),
              ),
              value: _idReturned,
              onChanged: (v) => setState(() => _idReturned = v),
              activeThumbColor: AppColors.primary,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surface,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SECTION 6: ACTIONS ─────────────────────────────────────────────────

  Widget _buildSection6Actions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _performCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                )
              : const Text(
                  'Complete Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // ─── CHECKOUT ACTION ─────────────────────────────────────────────────────

  Future<void> _performCheckout() async {
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    final now = DateTime.now().toUtc().toIso8601String();

    final data = <String, dynamic>{
      'checkin_id': _checkinId,
      'booking_id': _bookingId,
      'room_id': _roomId,
      'property_id': _propertyId,
      'staff_id': _staffId,
      'guest_name': _guestName,
      'room_number': _roomNumber,
      'checkout_time': now,
      'room_charges': _parseDouble(_roomChargesController.text),
      'restaurant_charges': _parseDouble(_restaurantController.text),
      'laundry_charges': _parseDouble(_laundryController.text),
      'minibar_charges': _parseDouble(_miniBarController.text),
      'damage_charges': _parseDouble(_damageController.text),
      'miscellaneous_charges': _parseDouble(_miscController.text),
      'discount': _parseDouble(_discountController.text),
      'gst': _parseDouble(_gstController.text),
      'total_amount': _totalAmount,
      'advance_paid': _advancePaid,
      'remaining_balance': _remainingBalance > 0 ? _remainingBalance : 0,
      'refund_amount': _refundAmount,
      'payment_status': _remainingBalance <= 0 ? 'paid' : (_advancePaid > 0 ? 'partial' : 'pending'),
      'key_returned': _keyReturned,
      'id_returned': _idReturned,
      'remarks': _remarksController.text,
    };

    await ref.read(checkOutProvider.notifier).performCheckOut(data: data);

    if (!mounted) return;
    final newState = ref.read(checkOutProvider);

    newState.whenOrNull(
      success: (message, checkoutId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.of(context).pop();
        ref.read(checkOutProvider.notifier).getPendingCheckOuts('prop_001');
      },
      error: (message) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
    );
  }

  // ─── SHARED BUILDERS ────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargeField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixText: '₹ ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppColors.surface,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
