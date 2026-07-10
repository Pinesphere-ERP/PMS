import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../../core/theme/app_colors.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // State variables for form fields
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  
  String? _cottageType;
  String? _viewPreference;
  String? _bedPreference;
  
  String? _idType;
  String? _paymentMethod;
  String? _paymentStatus;
  String? _bookingStatus = 'Pending';
  
  // Add-ons
  bool _addBreakfast = false;
  bool _addLunchDinner = false;
  bool _addAirportPickup = false;
  bool _addCampfire = false;
  bool _addBbq = false;
  bool _addExtraBed = false;
  bool _addPet = false;
  bool _addSightseeing = false;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  int get _numberOfNights {
    if (_checkInDate != null && _checkOutDate != null) {
      final diff = _checkOutDate!.difference(_checkInDate!).inDays;
      return diff > 0 ? diff : 0;
    }
    return 0;
  }

  int get _totalGuests => _adults + _children + _infants;

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

  Widget _buildTextField(String label, {bool isRequired = false, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        validator: isRequired ? (value) {
          if (value == null || value.isEmpty) return 'This field is required';
          return null;
        } : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, ValueChanged<String?> onChanged, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: isRequired ? (val) {
          if (val == null || val.isEmpty) return 'Please select an option';
          return null;
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Booking'),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. Guest Information
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('1. Guest Information'),
                  _buildTextField('Full Name', isRequired: true),
                  _buildTextField('Email Address', isRequired: true, keyboardType: TextInputType.emailAddress),
                  _buildTextField('Mobile Number', isRequired: true, keyboardType: TextInputType.phone),
                  _buildTextField('Country', isRequired: true),
                  _buildTextField('Special Requests', maxLines: 3),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Other sections will follow
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('2. Stay Details'),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _checkInDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _checkInDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Check-in Date *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                            child: Text(_checkInDate == null ? 'Select Date' : _dateFormat.format(_checkInDate!)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _checkOutDate ?? DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _checkOutDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Check-out Date *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                            child: Text(_checkOutDate == null ? 'Select Date' : _dateFormat.format(_checkOutDate!)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Number of Nights',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                          ),
                          child: Text('$_numberOfNights', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Arrival Time')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Guest Details
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('3. Guest Details'),
                  _buildDropdownField('Adults', ['1', '2', '3', '4', '5+'], '$_adults', (v) {
                    setState(() => _adults = int.parse(v!.replaceAll('+', '')));
                  }, isRequired: true),
                  _buildDropdownField('Children', ['0', '1', '2', '3', '4+'], '$_children', (v) {
                    setState(() => _children = int.parse(v!.replaceAll('+', '')));
                  }, isRequired: true),
                  _buildDropdownField('Infants', ['0', '1', '2'], '$_infants', (v) {
                    setState(() => _infants = int.parse(v!));
                  }),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Total Guests',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                    ),
                    child: Text('$_totalGuests', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Cottage Selection
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('4. Cottage Selection'),
                  _buildDropdownField('Cottage Type', ['Deluxe', 'Family', 'Luxury', 'Standard'], _cottageType, (v) => setState(() => _cottageType = v)),
                  _buildTextField('Number of Rooms/Cottages', keyboardType: TextInputType.number),
                  _buildDropdownField('View Preference', ['Garden', 'Lake', 'Forest', 'Mountain'], _viewPreference, (v) => setState(() => _viewPreference = v)),
                  _buildDropdownField('Bed Preference', ['King', 'Twin'], _bedPreference, (v) => setState(() => _bedPreference = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Pricing
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('5. Pricing'),
                  _buildTextField('Room Price per Night', keyboardType: TextInputType.number),
                  _buildTextField('Taxes', keyboardType: TextInputType.number),
                  _buildTextField('Additional Charges', keyboardType: TextInputType.number),
                  _buildTextField('Discount/Coupon Code'),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Total Amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                    ),
                    child: const Text('\$0.00', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Add-on Services
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('6. Add-on Services'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(label: const Text('Breakfast'), selected: _addBreakfast, onSelected: (v) => setState(() => _addBreakfast = v)),
                      FilterChip(label: const Text('Lunch/Dinner Package'), selected: _addLunchDinner, onSelected: (v) => setState(() => _addLunchDinner = v)),
                      FilterChip(label: const Text('Airport Pickup'), selected: _addAirportPickup, onSelected: (v) => setState(() => _addAirportPickup = v)),
                      FilterChip(label: const Text('Campfire'), selected: _addCampfire, onSelected: (v) => setState(() => _addCampfire = v)),
                      FilterChip(label: const Text('BBQ'), selected: _addBbq, onSelected: (v) => setState(() => _addBbq = v)),
                      FilterChip(label: const Text('Extra Bed'), selected: _addExtraBed, onSelected: (v) => setState(() => _addExtraBed = v)),
                      FilterChip(label: const Text('Pet Accommodation'), selected: _addPet, onSelected: (v) => setState(() => _addPet = v)),
                      FilterChip(label: const Text('Local Sightseeing'), selected: _addSightseeing, onSelected: (v) => setState(() => _addSightseeing = v)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7. Identity Verification
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('7. Identity Verification'),
                  _buildDropdownField('Government ID Type', ['Passport', 'Driver License', 'National ID'], _idType, (v) => setState(() => _idType = v)),
                  _buildTextField('ID Number'),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload ID (Optional)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 8. Payment
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('8. Payment'),
                  _buildDropdownField('Payment Method', ['Credit/Debit Card', 'UPI', 'Net Banking', 'Wallet', 'Pay at Property'], _paymentMethod, (v) => setState(() => _paymentMethod = v)),
                  _buildTextField('Advance Amount', keyboardType: TextInputType.number),
                  _buildDropdownField('Payment Status', ['Pending', 'Partial', 'Paid'], _paymentStatus, (v) => setState(() => _paymentStatus = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 9. Booking Confirmation
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('9. Booking Confirmation'),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Booking ID (Auto-generated)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                    ),
                    child: const Text('BKG-10293', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Booking Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                    ),
                    child: Text(_dateFormat.format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField('Booking Status', ['Pending', 'Confirmed', 'Cancelled', 'Completed'], _bookingStatus, (v) => setState(() => _bookingStatus = v)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Submit booking
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Created!')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
