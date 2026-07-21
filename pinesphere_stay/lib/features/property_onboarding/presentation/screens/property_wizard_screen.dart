import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/property_wizard_model.dart';
import '../providers/property_wizard_notifier.dart';
import '../../../../core/auth/session_context.dart';
import '../../../../core/auth/owner_onboarding_status.dart';
import '../../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';

class PropertyWizardScreen extends ConsumerStatefulWidget {
  const PropertyWizardScreen({super.key});

  @override
  ConsumerState<PropertyWizardScreen> createState() => _PropertyWizardScreenState();
}

class _PropertyWizardScreenState extends ConsumerState<PropertyWizardScreen> {
  final PageController _pageController = PageController();
  final int _totalSteps = 6;
  bool _isSubmitting = false;

  void _nextPage(PropertyWizardModel state, PropertyWizardNotifier notifier) {
    if (state.currentStep < _totalSteps - 1) {
      notifier.nextStep();
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _submitWizard(notifier);
    }
  }

  void _prevPage(PropertyWizardModel state, PropertyWizardNotifier notifier) {
    if (state.currentStep > 0) {
      notifier.previousStep();
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      context.go('/dashboard'); // Exit wizard if back pressed on first step
    }
  }

  Future<void> _submitWizard(PropertyWizardNotifier notifier) async {
    setState(() => _isSubmitting = true);

    final propertyId = ref.read(sessionContextProvider).activePropertyId;
    if (propertyId == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No active property found.')),
        );
      }
      return;
    }

    final success = await notifier.completeOnboarding(propertyId);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ref.read(sessionContextProvider.notifier).overrideOwnerStatus(OwnerOnboardingStatus.paymentPending);
        context.go('/subscription');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(propertyWizardProvider);
    final wizardNotifier = ref.read(propertyWizardProvider.notifier);

    // Sync PageController if state updated externally
    if (_pageController.hasClients && _pageController.page?.round() != wizardState.currentStep) {
      _pageController.animateToPage(
        wizardState.currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onBackground),
          onPressed: () => _prevPage(wizardState, wizardNotifier),
        ),
        title: Text(
          'Setup Property',
          style: GoogleFonts.outfit(color: AppColors.onBackground, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Log out',
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.read(sessionContextProvider.notifier).clear();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.onBackground),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: PineBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(wizardState.currentStep),
              const SizedBox(height: 24),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildBasicInfoStep(wizardState, wizardNotifier),
                    _buildLocationStep(wizardState, wizardNotifier),
                    _buildAmenitiesStep(wizardState, wizardNotifier),
                    _buildPhotosStep(wizardState, wizardNotifier),
                    _buildPoliciesStep(wizardState, wizardNotifier),
                    _buildReviewStep(wizardState),
                  ],
                ),
              ),
              _buildBottomControls(wizardState, wizardNotifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 4)] : [],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomControls(PropertyWizardModel state, PropertyWizardNotifier notifier) {
    final isLastStep = state.currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (state.currentStep > 0)
              TextButton(
                onPressed: _isSubmitting ? null : () => _prevPage(state, notifier),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: Text('Back', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
              )
            else
              const SizedBox.shrink(),
            
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _nextPage(state, notifier),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLastStep ? 'Submit Property' : 'Continue',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepWrapper(String title, String subtitle, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: child,
          ),
          const SizedBox(height: 48), // Padding for scrolling above controls
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue, Function(String) onChanged, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: AppColors.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AppColors.outline),
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBasicInfoStep(PropertyWizardModel wizardState, PropertyWizardNotifier notifier) {
    return _buildStepWrapper(
      'Basic Info',
      'Tell us about your property.',
      Column(
        children: [
          _buildTextField('Property Name', wizardState.name, (val) => notifier.updateBasicInfo(name: val)),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: DropdownButtonFormField<String>(
              initialValue: ['HOTEL', 'RESORT', 'HOSTEL', 'APARTMENT', 'GUESTHOUSE'].contains(wizardState.propertyType) ? wizardState.propertyType : 'HOTEL',
              dropdownColor: AppColors.surfaceContainerHigh,
              decoration: InputDecoration(
                labelText: 'Property Type',
                labelStyle: GoogleFonts.inter(color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: ['HOTEL', 'RESORT', 'HOSTEL', 'APARTMENT', 'GUESTHOUSE']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(color: AppColors.onSurface))))
                  .toList(),
              onChanged: (val) => notifier.updateBasicInfo(propertyType: val),
            ),
          ),
          DropdownButtonFormField<int>(
            initialValue: [1, 2, 3, 4, 5].contains(wizardState.starCategory) ? wizardState.starCategory : 3,
            dropdownColor: AppColors.surfaceContainerHigh,
            decoration: InputDecoration(
              labelText: 'Star Category',
              labelStyle: GoogleFonts.inter(color: AppColors.outline),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: [1, 2, 3, 4, 5]
                .map((e) => DropdownMenuItem(value: e, child: Text('$e Star', style: GoogleFonts.inter(color: AppColors.onSurface))))
                .toList(),
            onChanged: (val) => notifier.updateBasicInfo(starCategory: val),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(PropertyWizardModel wizardState, PropertyWizardNotifier notifier) {
    return _buildStepWrapper(
      'Location',
      'Where is your property located?',
      Column(
        children: [
          _buildTextField('Address', wizardState.address, (val) => notifier.updateLocation(address: val)),
          Row(
            children: [
              Expanded(child: _buildTextField('City', wizardState.city, (val) => notifier.updateLocation(city: val))),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('State/Region', wizardState.state, (val) => notifier.updateLocation(stateLoc: val))),
            ],
          ),
          _buildTextField('Country', wizardState.country, (val) => notifier.updateLocation(country: val)),
          _buildTextField('Zip/Postal Code', wizardState.zipCode, (val) => notifier.updateLocation(zipCode: val)),
        ],
      ),
    );
  }

  Widget _buildAmenitiesStep(PropertyWizardModel wizardState, PropertyWizardNotifier notifier) {
    final availableAmenities = ['WiFi', 'Pool', 'Parking', 'Gym', 'Restaurant', 'Spa', 'Bar', 'Room Service', 'Air Conditioning', 'Pet Friendly'];
    return _buildStepWrapper(
      'Amenities',
      'Select the amenities you offer.',
      Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: availableAmenities.map((amenity) {
          final isSelected = wizardState.amenities.contains(amenity);
          return FilterChip(
            label: Text(amenity, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            selected: isSelected,
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerLowest,
            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            onSelected: (selected) {
              final newAmenities = List<String>.from(wizardState.amenities);
              if (selected) {
                newAmenities.add(amenity);
              } else {
                newAmenities.remove(amenity);
              }
              notifier.updateAmenities(newAmenities);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotosStep(PropertyWizardModel wizardState, PropertyWizardNotifier notifier) {
    return _buildStepWrapper(
      'Photos',
      'Upload images of your property to attract guests.',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              // Mock photo upload
              notifier.updateImages([...wizardState.images, 'mock_image_url_${wizardState.images.length}.png']);
            },
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text('Tap to upload photos', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (wizardState.images.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: wizardState.images.map((img) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1542314831-c6a4d142104d?w=200'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          final newImages = List<String>.from(wizardState.images)..remove(img);
                          notifier.updateImages(newImages);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPoliciesStep(PropertyWizardModel wizardState, PropertyWizardNotifier notifier) {
    return _buildStepWrapper(
      'Policies',
      'Set your property rules and times.',
      Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField('Check-in (e.g. 14:00)', wizardState.checkInTime, (val) => notifier.updatePolicies(checkInTime: val))),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Check-out (e.g. 11:00)', wizardState.checkOutTime, (val) => notifier.updatePolicies(checkOutTime: val))),
            ],
          ),
          _buildTextField('Cancellation Policy', wizardState.cancellationPolicy, (val) => notifier.updatePolicies(cancellationPolicy: val), maxLines: 3),
          _buildTextField('House Rules', wizardState.houseRules, (val) => notifier.updatePolicies(houseRules: val), maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildReviewStep(PropertyWizardModel wizardState) {
    Widget buildReviewRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(label, style: GoogleFonts.inter(color: AppColors.outline, fontWeight: FontWeight.w500))),
            Expanded(flex: 3, child: Text(value, style: GoogleFonts.inter(color: AppColors.onSurface, fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }

    return _buildStepWrapper(
      'Review',
      'Make sure everything looks good.',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildReviewRow('Property Name', wizardState.name.isEmpty ? 'Not set' : wizardState.name),
          buildReviewRow('Type', wizardState.propertyType.isEmpty ? 'Not set' : wizardState.propertyType),
          buildReviewRow('Location', '${wizardState.city.isEmpty ? 'City' : wizardState.city}, ${wizardState.state.isEmpty ? 'State' : wizardState.state}'),
          buildReviewRow('Amenities', wizardState.amenities.isEmpty ? 'None selected' : wizardState.amenities.join(', ')),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'By submitting, you agree that all information is accurate. You can upgrade your subscription on the next screen.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
