import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/property_onboarding_widgets.dart';

class PropertyOnboardingScreen extends StatefulWidget {
  const PropertyOnboardingScreen({super.key});

  @override
  State<PropertyOnboardingScreen> createState() => _PropertyOnboardingScreenState();
}

class _PropertyOnboardingScreenState extends State<PropertyOnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 13;
  
  final List<String> _stepTitles = [
    'Owner Registration',
    'Business Info',
    'Property Info',
    'Property Location',
    'Ownership Details',
    'Room Configuration',
    'Room Amenities',
    'Hotel Amenities',
    'Property Photos',
    'Hotel Policies',
    'Pricing',
    'Inventory & Availability',
    'Bank Details & Docs',
  ];

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Final submit
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding submitted for review!')),
      );
      Navigator.of(context).pop();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0: return const Step1OwnerRegistration();
      case 1: return const Step2BusinessInfo();
      case 2: return const Step3PropertyInfo();
      case 3: return const Step4PropertyLocation();
      case 4: return const Step5OwnershipDetails();
      case 5: return const Step6RoomConfiguration();
      case 6: return const Step7RoomAmenities();
      case 7: return const Step8HotelAmenities();
      case 8: return const Step9PropertyPhotos();
      case 9: return const Step10HotelPolicies();
      case 10: return const Step11Pricing();
      case 11: return const Step12Inventory();
      case 12: return const Step13BankDetails();
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Property Onboarding', style: TextStyle(color: AppColors.onBackground)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onBackground),
      ),
      body: Column(
        children: [
          // Custom Horizontal Step Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: AppColors.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _stepTitles[_currentStep],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildCurrentStepWidget(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_currentStep == _totalSteps - 1 ? 'Submit for Review' : 'Save & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
