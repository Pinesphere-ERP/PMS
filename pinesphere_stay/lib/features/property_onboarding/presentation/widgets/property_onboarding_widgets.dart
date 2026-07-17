import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class Step1BasicInfo extends StatelessWidget {
  const Step1BasicInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Owner & Business Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 24),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Owner Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Owner Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Business / Company Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'GST Number (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.receipt)),
        ),
      ],
    );
  }
}

class Step2LocationInventory extends StatelessWidget {
  const Step2LocationInventory({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Property Location & Rooms', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 24),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Property Name (e.g., Pinesphere Grand)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.hotel)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Full Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()))),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()))),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Room Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Total Number of Rooms', border: OutlineInputBorder(), prefixIcon: Icon(Icons.meeting_room)),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

class Step3AmenitiesPolicies extends StatelessWidget {
  const Step3AmenitiesPolicies({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amenities & Bank Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 24),
        const Text('Select Amenities:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(label: const Text('Free WiFi'), selected: true, onSelected: (val) {}),
            FilterChip(label: const Text('Swimming Pool'), selected: false, onSelected: (val) {}),
            FilterChip(label: const Text('Restaurant'), selected: true, onSelected: (val) {}),
            FilterChip(label: const Text('Gym'), selected: false, onSelected: (val) {}),
            FilterChip(label: const Text('Parking'), selected: true, onSelected: (val) {}),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Bank Details for Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Account Holder Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance)),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: 'IFSC / Swift Code', border: OutlineInputBorder(), prefixIcon: Icon(Icons.code)),
        ),
      ],
    );
  }
}
