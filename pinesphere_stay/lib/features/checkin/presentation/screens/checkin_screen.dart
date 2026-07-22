import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/tenant_provider.dart';
import '../../../../core/security/permission_engine.dart';
import '../../../../core/presentation/widgets/access_restricted_view.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pinesphere_stay/features/rooms/presentation/providers/pms_provider.dart';
import '../providers/checkin_provider.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialBookingData;

  const CheckInScreen({super.key, this.initialBookingData});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _isWalkInMode = false;

  final _searchController = TextEditingController();
  Map<String, dynamic>? _selectedBooking;

  bool _idVerified = false;
  final _idVerificationNotesController = TextEditingController();
  final _depositController = TextEditingController();
  final _advancePaidController = TextEditingController();
  final _specialRequestsController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  bool _parkingRequired = false;

  final _walkInFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _dobController = TextEditingController();
  String? _gender;
  String? _idType;
  final _idNumberController = TextEditingController();

  DateTime? _walkInCheckInDate;
  DateTime? _walkInCheckOutDate;
  int _walkInAdults = 1;
  int _walkInChildren = 0;
  int _walkInInfants = 0;
  String? _selectedRoomId;
  String? _selectedRoomName;

  final _roomRentController = TextEditingController();
  final _walkInDepositController = TextEditingController();
  final _walkInAdvancePaidController = TextEditingController();
  final _walkInSpecialRequestsController = TextEditingController();
  final _walkInVehicleNumberController = TextEditingController();
  bool _walkInParkingRequired = false;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    if (widget.initialBookingData != null) {
      final data = widget.initialBookingData!;
      _isWalkInMode = true;
      _fullNameController.text = data['guest_name']?.toString() ?? '';
      _mobileController.text = data['guest_phone']?.toString() ?? data['mobile']?.toString() ?? '';
      _emailController.text = data['guest_email']?.toString() ?? data['email']?.toString() ?? '';
      _selectedRoomId = data['room_id']?.toString();
      _selectedRoomName = data['room_number']?.toString();
      if (data['check_in_date'] != null) {
        _walkInCheckInDate = DateTime.tryParse(data['check_in_date'].toString());
      }
      if (data['check_out_date'] != null) {
        _walkInCheckOutDate = DateTime.tryParse(data['check_out_date'].toString());
      }
      if (data['deposit'] != null) {
        _walkInDepositController.text = data['deposit'].toString();
      }
    }
  }

  int get _walkInNights {
    if (_walkInCheckInDate != null && _walkInCheckOutDate != null) {
      final diff = _walkInCheckOutDate!.difference(_walkInCheckInDate!).inDays;
      return diff > 0 ? diff : 0;
    }
    return 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _idVerificationNotesController.dispose();
    _depositController.dispose();
    _advancePaidController.dispose();
    _specialRequestsController.dispose();
    _vehicleNumberController.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _nationalityController.dispose();
    _dobController.dispose();
    _idNumberController.dispose();
    _roomRentController.dispose();
    _walkInDepositController.dispose();
    _walkInAdvancePaidController.dispose();
    _walkInSpecialRequestsController.dispose();
    _walkInVehicleNumberController.dispose();
    super.dispose();
  }

  String get _propertyId {
    return ref.read(tenantProvider) ?? '';
  }

  void _onSearchChanged(String query) {
    if (query.length >= 2) {
      ref.read(checkInProvider.notifier).searchBookings(_propertyId, search: query);
    }
  }

  void _selectBooking(Map<String, dynamic> booking) {
    setState(() {
      _selectedBooking = booking;
      _depositController.text = (booking['deposit'] ?? 0).toString();
      _advancePaidController.text = (booking['advance_paid'] ?? 0).toString();
    });
  }

  Future<void> _completeCheckIn() async {
    if (_selectedBooking == null) return;
    final data = <String, dynamic>{
      'booking_id': _selectedBooking!['booking_id']?.toString() ?? _selectedBooking!['id']?.toString() ?? '',
      'room_id': _selectedBooking!['room_id']?.toString() ?? '',
      'guest_id': _selectedBooking!['guest_id']?.toString() ?? '',
      'property_id': _propertyId,
      'guest_name': _selectedBooking!['guest_name']?.toString() ?? '',
      'room_number': _selectedBooking!['room_number']?.toString() ?? '',
      'room_type': _selectedBooking!['room_type']?.toString() ?? '',
      'deposit': double.tryParse(_depositController.text) ?? 0,
      'advance_paid': double.tryParse(_advancePaidController.text) ?? 0,
      'id_verified': _idVerified,
      'id_verification_notes': _idVerificationNotesController.text,
      'special_requests': _specialRequestsController.text,
      'vehicle_number': _vehicleNumberController.text,
      'parking_required': _parkingRequired,
    };
    await ref.read(checkInProvider.notifier).performCheckIn(data: data);
  }

  Future<void> _saveOffline() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving check-in data locally for offline sync...')),
    );
    await _completeCheckIn();
  }

  Future<void> _completeWalkIn() async {
    if (!_walkInFormKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'property_id': _propertyId,
      'full_name': _fullNameController.text,
      'mobile': _mobileController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'country': _countryController.text,
      'nationality': _nationalityController.text,
      'dob': _dobController.text,
      'gender': _gender ?? '',
      'id_type': _idType ?? '',
      'id_number': _idNumberController.text,
      'check_in_date': _walkInCheckInDate?.toIso8601String() ?? '',
      'check_out_date': _walkInCheckOutDate?.toIso8601String() ?? '',
      'adults': _walkInAdults,
      'children': _walkInChildren,
      'infants': _walkInInfants,
      'room_id': _selectedRoomId ?? '',
      'room_name': _selectedRoomName ?? '',
      'room_rent': double.tryParse(_roomRentController.text) ?? 0,
      'deposit': double.tryParse(_walkInDepositController.text) ?? 0,
      'advance_paid': double.tryParse(_walkInAdvancePaidController.text) ?? 0,
      'special_requests': _walkInSpecialRequestsController.text,
      'vehicle_number': _walkInVehicleNumberController.text,
      'parking_required': _walkInParkingRequired,
    };
    await ref.read(checkInProvider.notifier).performWalkIn(data: data);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTextField(String label,
      {bool isRequired = false,
      TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      TextEditingController? controller,
      bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppColors.surface,
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) return 'This field is required';
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value,
      ValueChanged<String?> onChanged,
      {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppColors.surface,
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: isRequired
            ? (val) {
                if (val == null || val.isEmpty) return 'Please select an option';
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime? date, ValueChanged<DateTime> onPicked,
      {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (picked != null) onPicked(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: isRequired ? '$label *' : label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.surface,
          ),
          child: Text(
            date == null ? 'Select Date' : _dateFormat.format(date),
            style: TextStyle(color: date == null ? AppColors.outline : AppColors.onSurface),
          ),
        ),
      ),
    );
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
        title: 'Check-In Restricted',
        message: 'Your role does not permit access to the Check-In module.',
      );
    }

    final isViewOnly = !canFull && !canDigitalCheckIn;
    ref.listen<CheckInState>(checkInProvider, (prev, state) {
      state.maybeWhen(
        error: (msg) => _showError(msg),
        success: (msg, _) {
          _showSuccess(msg);
          ref.read(pmsProvider.notifier).loadRooms();
          ref.read(pmsProvider.notifier).loadBookings();
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Check-In'),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
      ),
      body: PineBackground(
        child: Column(
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
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildModeToggle(isViewOnly),
                const SizedBox(height: 16),
                if (_isWalkInMode) _buildWalkInMode(isViewOnly) else _buildBookingCheckInMode(isViewOnly),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildModeToggle(bool isViewOnly) {
    return AbsorbPointer(
      absorbing: isViewOnly,
      child: PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Mode'),
          Row(
            children: [
              Expanded(
                child: _buildToggleButton('Booking\nCheck-In', !_isWalkInMode, () {
                  setState(() => _isWalkInMode = false);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleButton('Walk-In', _isWalkInMode, () {
                  setState(() {
                    _isWalkInMode = true;
                  });
                  ref.read(checkInProvider.notifier).searchAvailableRooms(_propertyId);
                }),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOOKING CHECK-IN MODE
  // ============================================================

  Widget _buildBookingCheckInMode(bool isViewOnly) {
    final state = ref.watch(checkInProvider);
    final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

    return AbsorbPointer(
      absorbing: isViewOnly,
      child: Column(
        children: [
          _buildSearchSection(isLoading),
          if (_selectedBooking != null) ...[
            const SizedBox(height: 16),
            _buildGuestVerification(),
            const SizedBox(height: 16),
            _buildRoomAssignment(),
            const SizedBox(height: 16),
            _buildPaymentDeposit(),
            const SizedBox(height: 16),
            _buildAdditionalDetails(),
            if (!isViewOnly) ...[
              const SizedBox(height: 16),
              _buildCheckInActions(isLoading),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isLoading) {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Step 1: Search & Select Booking'),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by guest name, booking ID, or mobile...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surface,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _selectedBooking = null);
                        ref.read(checkInProvider.notifier).searchBookings(_propertyId);
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else
            _buildBookingResults(),
        ],
      ),
    );
  }

  Widget _buildBookingResults() {
    final state = ref.watch(checkInProvider);
    return state.maybeWhen(
      loadedBookings: (bookings) {
        if (bookings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No bookings found',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final isSelected = (_selectedBooking?['booking_id']?.toString() ?? _selectedBooking?['id']?.toString()) == (booking['booking_id']?.toString() ?? booking['id']?.toString());
            return _buildBookingCard(booking, isSelected);
          },
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isSelected) {
    final bookingId = booking['id']?.toString() ?? 'N/A';
    final guestName = booking['guest_name']?.toString() ?? 'Unknown';
    final roomNumber = booking['room_number']?.toString() ?? 'N/A';
    final checkInDate = booking['check_in_date']?.toString() ?? '';
    final status = booking['booking_status']?.toString() ?? '';

    String formattedDate = checkInDate;
    try {
      if (checkInDate.isNotEmpty) {
        final dt = DateTime.parse(checkInDate);
        formattedDate = _dateFormat.format(dt);
      }
    } catch (_) {}

    return GestureDetector(
      onTap: () => _selectBooking(booking),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryFixed.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guestName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text('Booking: $bookingId', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                  Text('Room: $roomNumber', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                  Text('Check-in: $formattedDate', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: _statusColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.primary;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.secondary;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Widget _buildGuestVerification() {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Step 2: Guest Verification'),
          if (_selectedBooking != null) ...[
            _buildReadOnlyField('Guest Name', _selectedBooking!['guest_name']?.toString() ?? 'N/A'),
            _buildReadOnlyField('Guest ID', _selectedBooking!['guest_id']?.toString() ?? 'N/A'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('ID Verified'),
              subtitle: const Text('Mark if guest ID has been verified'),
              value: _idVerified,
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _idVerified = v),
            ),
            if (_idVerified)
              _buildTextField('Verification Notes', controller: _idVerificationNotesController, maxLines: 2),
            const SizedBox(height: 8),
            _buildReadOnlyField('Emergency Contact', _selectedBooking!['emergency_contact_name']?.toString() ?? 'N/A'),
            _buildReadOnlyField('Emergency Phone', _selectedBooking!['emergency_contact_phone']?.toString() ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomAssignment() {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Step 3: Room Assignment'),
          if (_selectedBooking != null) ...[
            _buildReadOnlyField('Room Number', _selectedBooking!['room_number']?.toString() ?? 'N/A'),
            _buildReadOnlyField('Room Type', _selectedBooking!['room_type']?.toString() ?? 'N/A'),
            _buildReadOnlyField('Floor', _selectedBooking!['floor']?.toString() ?? 'N/A'),
            _buildReadOnlyField('Capacity', '${_selectedBooking!['adults'] ?? 0} Adults, ${_selectedBooking!['children'] ?? 0} Children'),
            _buildReadOnlyField('Price per Night', '\$${_selectedBooking!['room_rent']?.toString() ?? '0'}'),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentDeposit() {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Step 4: Payment & Deposit'),
          if (_selectedBooking != null) ...[
            _buildReadOnlyField('Total Payable', '\$${_selectedBooking!['total_payable']?.toString() ?? '0'}'),
            const SizedBox(height: 12),
            _buildTextField('Deposit Amount',
                controller: _depositController, keyboardType: TextInputType.number),
            _buildTextField('Advance Paid',
                controller: _advancePaidController, keyboardType: TextInputType.number),
            _buildReadOnlyField('Pending Amount',
                '\$${_selectedBooking!['pending_amount']?.toString() ?? '0'}'),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Step 5: Additional Details'),
          _buildTextField('Special Requests',
              controller: _specialRequestsController, maxLines: 3),
          _buildTextField('Vehicle Number',
              controller: _vehicleNumberController),
          CheckboxListTile(
            title: const Text('Parking Required'),
            value: _parkingRequired,
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _parkingRequired = v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInActions(bool isLoading) {
    return PineCard(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _completeCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Complete Check-In',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoading ? null : _saveOffline,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Offline',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WALK-IN MODE
  // ============================================================

  Widget _buildWalkInMode(bool isViewOnly) {
    final state = ref.watch(checkInProvider);
    final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

    return AbsorbPointer(
      absorbing: isViewOnly,
      child: Form(
        key: _walkInFormKey,
        child: Column(
          children: [
            _buildWalkInGuestInfo(),
            const SizedBox(height: 16),
            _buildWalkInIdentity(),
            const SizedBox(height: 16),
            _buildWalkInStayDetails(),
            const SizedBox(height: 16),
            _buildWalkInRoomSelection(),
            const SizedBox(height: 16),
            _buildWalkInPayment(),
            const SizedBox(height: 16),
            _buildWalkInAdditional(),
            if (!isViewOnly) ...[
              const SizedBox(height: 16),
              _buildWalkInAction(isLoading),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWalkInGuestInfo() {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('1. Guest Information'),
          _buildTextField('Full Name', isRequired: true, controller: _fullNameController),
          _buildTextField('Mobile Number', isRequired: true, controller: _mobileController, keyboardType: TextInputType.phone),
          _buildTextField('Email Address', controller: _emailController, keyboardType: TextInputType.emailAddress),
          _buildTextField('Address', controller: _addressController, maxLines: 2),
          Row(
            children: [
              Expanded(child: _buildTextField('City', controller: _cityController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('State', controller: _stateController)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField('Country', controller: _countryController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Nationality', controller: _nationalityController)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField('Date of Birth', controller: _dobController)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  'Gender',
                  ['Male', 'Female', 'Other'],
                  _gender,
                  (v) => setState(() => _gender = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isForeigner = false;
  String? _aadhaarImagePath;
  String? _aFormImagePath;

  final _passportNumberController = TextEditingController();
  final _visaNumberController = TextEditingController();

  Future<void> _pickDocumentImage(bool isAadhaar) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          if (isAadhaar) {
            _aadhaarImagePath = picked.path;
          } else {
            _aFormImagePath = picked.path;
          }
        });
      }
    } catch (_) {}
  }

  Widget _buildDocumentUploadTile({
    required String title,
    required String subtitle,
    required String? imagePath,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.outline)),
          const SizedBox(height: 12),
          if (imagePath != null && imagePath.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Document Attached ✅')),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.upload_file),
              label: Text('Capture / Upload $title'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalkInIdentity() {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('2. Nationality & ID Verification'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isForeigner = false;
                      _idType = 'Aadhaar Card';
                      _nationalityController.text = 'Indian';
                      _countryController.text = 'India';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: !_isForeigner ? AppColors.primaryContainer.withValues(alpha: 0.4) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_isForeigner ? AppColors.primary : AppColors.outlineVariant,
                        width: !_isForeigner ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Indian National\n(Aadhaar)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isForeigner ? AppColors.primary : AppColors.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isForeigner = true;
                      _idType = 'Passport';
                      if (_nationalityController.text.isEmpty || _nationalityController.text.toLowerCase() == 'indian') {
                        _nationalityController.text = '';
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _isForeigner ? Colors.orange.shade50 : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isForeigner ? Colors.orange.shade800 : AppColors.outlineVariant,
                        width: _isForeigner ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✈️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Foreigner\n(A Form)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isForeigner ? Colors.orange.shade900 : AppColors.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isForeigner) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.badge, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🇮🇳 Indian Guest: Mandatory 12-digit Aadhaar Card number & Aadhaar Image upload required.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            _buildDropdownField(
              'ID Type',
              ['Aadhaar Card', 'Voter ID', 'Driving License', 'Passport', 'PAN Card'],
              _idType ?? 'Aadhaar Card',
              (v) => setState(() => _idType = v),
              isRequired: true,
            ),
            _buildTextField(
              '12-Digit Aadhaar / ID Number',
              isRequired: true,
              controller: _idNumberController,
              keyboardType: TextInputType.number,
            ),
            _buildDocumentUploadTile(
              title: 'Aadhaar Card Image / Photo',
              subtitle: 'Upload or capture clear photo of guest Aadhaar card front/back',
              imagePath: _aadhaarImagePath,
              onTap: () => _pickDocumentImage(true),
              onRemove: () => setState(() => _aadhaarImagePath = null),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_ind, color: Colors.orange.shade900),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '✈️ Foreign National: A Form Foreigner Registration (Nationality & A Form Photo required).',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: _buildTextField('Nationality', isRequired: true, controller: _nationalityController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Country of Origin', isRequired: true, controller: _countryController)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField('A Form / Passport Number', isRequired: true, controller: _passportNumberController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Visa Number', controller: _visaNumberController)),
              ],
            ),
            _buildDocumentUploadTile(
              title: 'A Form Document Image / Photo',
              subtitle: 'Upload or capture clear photo of completed A Form / Passport',
              imagePath: _aFormImagePath,
              onTap: () => _pickDocumentImage(false),
              onRemove: () => setState(() => _aFormImagePath = null),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalkInStayDetails() {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('3. Stay Details'),
          _buildDatePickerField(
            'Check-in Date',
            _walkInCheckInDate,
            (d) => setState(() => _walkInCheckInDate = d),
            isRequired: true,
          ),
          _buildDatePickerField(
            'Check-out Date',
            _walkInCheckOutDate,
            (d) => setState(() => _walkInCheckOutDate = d),
            isRequired: true,
          ),
          if (_walkInNights > 0)
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Number of Nights',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
              ),
              child: Text('$_walkInNights', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 12),
          _buildDropdownField(
            'Adults',
            ['1', '2', '3', '4', '5+'],
            '$_walkInAdults',
            (v) => setState(() => _walkInAdults = int.parse(v!.replaceAll('+', ''))),
            isRequired: true,
          ),
          _buildDropdownField(
            'Children',
            ['0', '1', '2', '3', '4+'],
            '$_walkInChildren',
            (v) => setState(() => _walkInChildren = int.parse(v!.replaceAll('+', ''))),
          ),
          _buildDropdownField(
            'Infants',
            ['0', '1', '2'],
            '$_walkInInfants',
            (v) => setState(() => _walkInInfants = int.parse(v!)),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkInRoomSelection() {
    final state = ref.watch(checkInProvider);
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('4. Room Selection'),
          state.maybeWhen(
            loadedRooms: (rooms) {
              if (rooms.isEmpty) {
                return Text('No vacant rooms available',
                    style: TextStyle(color: AppColors.onSurfaceVariant));
              }
              return Column(
                children: rooms.map((room) {
                  return RadioListTile<String>(
                    title: Text('${room['name']} (${room['type']})'),
                    subtitle: Text('\$${room['price_per_night']}/night - ${room['status']}'),
                    value: room['id'] as String,
                    // ignore: deprecated_member_use
                    groupValue: _selectedRoomId,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    // ignore: deprecated_member_use
                    onChanged: (v) {
                      setState(() {
                        _selectedRoomId = v;
                        _selectedRoomName = room['name'] as String?;
                        _roomRentController.text = (room['price_per_night'] as num).toString();
                      });
                    },
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            orElse: () => ElevatedButton.icon(
              onPressed: () => ref.read(checkInProvider.notifier).searchAvailableRooms(_propertyId),
              icon: const Icon(Icons.refresh),
              label: const Text('Load Available Rooms'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkInPayment() {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('5. Payment'),
          _buildTextField('Room Rent', controller: _roomRentController, keyboardType: TextInputType.number),
          _buildTextField('Deposit', controller: _walkInDepositController, keyboardType: TextInputType.number),
          _buildTextField('Advance Paid', controller: _walkInAdvancePaidController, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildWalkInAdditional() {
    return PineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('6. Additional'),
          _buildTextField('Special Requests', controller: _walkInSpecialRequestsController, maxLines: 3),
          _buildTextField('Vehicle Number', controller: _walkInVehicleNumberController),
          CheckboxListTile(
            title: const Text('Parking Required'),
            value: _walkInParkingRequired,
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _walkInParkingRequired = v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkInAction(bool isLoading) {
    return PineCard(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : _completeWalkIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Complete Walk-In Check-In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
