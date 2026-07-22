import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/property_wizard_model.dart';
import '../providers/property_wizard_notifier.dart';
import '../../../../core/auth/session_context.dart';
import '../../../../core/auth/owner_onboarding_status.dart';
import '../../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';


class PropertyWizardScreen extends ConsumerWidget {
  const PropertyWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(propertyWizardProvider);
    final wizardNotifier = ref.read(propertyWizardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Setup Wizard'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/dashboard'), // Abort or save draft
        ),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: wizardState.currentStep,
        onStepTapped: (step) => wizardNotifier.jumpToStep(step),
        onStepContinue: () {
          if (wizardState.currentStep < 5) {
            wizardNotifier.nextStep();
          } else {
            // Submit
            _submitWizard(context, ref, wizardNotifier);
          }
        },
        onStepCancel: () {
          if (wizardState.currentStep > 0) {
            wizardNotifier.previousStep();
          }
        },
        steps: [
          _buildBasicInfoStep(wizardState, wizardNotifier),
          _buildLocationStep(wizardState, wizardNotifier),
          _buildAmenitiesStep(wizardState, wizardNotifier),
          _buildPhotosStep(wizardState, wizardNotifier),
          _buildPoliciesStep(wizardState, wizardNotifier),
          _buildReviewStep(wizardState),
        ],
      ),
    );
  }

  void _submitWizard(BuildContext context, WidgetRef ref,
      PropertyWizardNotifier notifier) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Call submit
    final session = ref.read(sessionContextProvider);
    final propertyId = session.activePropertyId ?? session.user?.propertyId;
    if (propertyId == null) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No active property found.')),
        );
      }
      return;
    }
    
    final success = await notifier.completeOnboarding(propertyId);

    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading
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
          TextFormField(
            initialValue: wizardState.name,
            decoration: const InputDecoration(labelText: 'Property Name'),
            onChanged: (val) => notifier.updateBasicInfo(name: val),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: wizardState.propertyType,
            decoration: const InputDecoration(labelText: 'Property Type'),
            items: ['HOTEL', 'RESORT', 'HOSTEL', 'APARTMENT', 'GUESTHOUSE']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => notifier.updateBasicInfo(propertyType: val),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: wizardState.starCategory,
            decoration: const InputDecoration(labelText: 'Star Category'),
            items: [1, 2, 3, 4, 5]
                .map((e) => DropdownMenuItem(value: e, child: Text('$e Star')))
                .toList(),
            onChanged: (val) => notifier.updateBasicInfo(starCategory: val),
          ),
        ],
      ),
    );
  }

  Step _buildLocationStep(PropertyWizardModel wizardState, PropertyWizardNotifier notifier) {
    return Step(
      title: const Text('Location'),
      isActive: wizardState.currentStep >= 1,
      state: wizardState.currentStep > 1 ? StepState.complete : StepState.editing,
      content: Column(
        children: [
          TextFormField(
            initialValue: wizardState.address,
            decoration: const InputDecoration(labelText: 'Address'),
            onChanged: (val) => notifier.updateLocation(address: val),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: wizardState.city,
                  decoration: const InputDecoration(labelText: 'City'),
                  onChanged: (val) => notifier.updateLocation(city: val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: wizardState.state,
                  decoration: const InputDecoration(labelText: 'State/Region'),
                  onChanged: (val) => notifier.updateLocation(stateLoc: val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Step _buildAmenitiesStep(PropertyWizardModel wizardState, PropertyWizardNotifier notifier) {
    // A simple multi-select or chip list for amenities
    final availableAmenities = ['WiFi', 'Pool', 'Parking', 'Gym', 'Restaurant', 'Spa', 'Bar'];
    return Step(
      title: const Text('Amenities'),
      isActive: wizardState.currentStep >= 2,
      state: wizardState.currentStep > 2 ? StepState.complete : StepState.editing,
      content: Wrap(
        spacing: 8.0,
        children: availableAmenities.map((amenity) {
          final isSelected = wizardState.amenities.contains(amenity);
          return FilterChip(
            label: Text(amenity),
            selected: isSelected,
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

  Step _buildPhotosStep(PropertyWizardModel wizardState, PropertyWizardNotifier notifier) {
    return Step(
      title: const Text('Photos'),
      isActive: wizardState.currentStep >= 3,
      state: wizardState.currentStep > 3 ? StepState.complete : StepState.editing,
      content: Column(
        children: [
          const Text('Upload photos of your property.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Select Photos'),
            onPressed: () {
              // Mock photo upload
              notifier.updateImages([...wizardState.images, 'mock_image_url.png']);
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: wizardState.images
                .map<Widget>((img) => Chip(
                      label: const Text('Image Uploaded'),
                      onDeleted: () {
                        final newImages = List<String>.from(wizardState.images)..remove(img);
                        notifier.updateImages(newImages);
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Step _buildPoliciesStep(PropertyWizardModel wizardState, PropertyWizardNotifier notifier) {
    return Step(
      title: const Text('Policies'),
      isActive: wizardState.currentStep >= 4,
      state: wizardState.currentStep > 4 ? StepState.complete : StepState.editing,
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: wizardState.checkInTime,
                  decoration: const InputDecoration(labelText: 'Check-in Time (e.g. 14:00)'),
                  onChanged: (val) => notifier.updatePolicies(checkInTime: val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: wizardState.checkOutTime,
                  decoration: const InputDecoration(labelText: 'Check-out Time (e.g. 11:00)'),
                  onChanged: (val) => notifier.updatePolicies(checkOutTime: val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: wizardState.cancellationPolicy,
            decoration: const InputDecoration(labelText: 'Cancellation Policy'),
            maxLines: 3,
            onChanged: (val) => notifier.updatePolicies(cancellationPolicy: val),
          ),
        ],
      ),
    );
  }

  Step _buildReviewStep(PropertyWizardModel wizardState) {
    return Step(
      title: const Text('Review'),
      isActive: wizardState.currentStep >= 5,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Property Name: ${wizardState.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Type: ${wizardState.propertyType}'),
          Text('Location: ${wizardState.city}, ${wizardState.state}'),
          Text('Amenities: ${wizardState.amenities.join(', ')}'),
          const SizedBox(height: 16),
          const Text('By submitting, you agree that all information is accurate and will be reviewed by our team before going live.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
}
