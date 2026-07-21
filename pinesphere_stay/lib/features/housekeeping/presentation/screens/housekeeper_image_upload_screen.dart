import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinesphere_stay/core/theme/app_colors.dart';
import 'package:pinesphere_stay/core/presentation/widgets/design_system/pine_background.dart';
import 'package:pinesphere_stay/features/housekeeping/presentation/providers/housekeeper_provider.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/auth_notifier.dart';

class HousekeeperImageUploadScreen extends ConsumerStatefulWidget {
  final String roomId;
  const HousekeeperImageUploadScreen({super.key, required this.roomId});

  @override
  ConsumerState<HousekeeperImageUploadScreen> createState() => _HousekeeperImageUploadScreenState();
}

class _HousekeeperImageUploadScreenState extends ConsumerState<HousekeeperImageUploadScreen> {
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() {
        _images.add(image);
      });
    }
  }

  Future<void> _submit() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture at least one photo of the clean room.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = ref.read(authProvider);
      final propertyId = auth.maybeWhen(authenticated: (u) => u.propertyId, orElse: () => '');
      
      // In a real app, upload images to storage here and get URLs back.
      // We pass fake paths to trigger the provider logic which sends to the backend.
      final paths = _images.map((e) => e.path).toList();
      
      await ref.read(housekeeperControllerProvider).completeCleaning(widget.roomId, paths, propertyId!);
      
      if (mounted) {
        context.go('/housekeeper-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Cleaning'),
        backgroundColor: AppColors.surface,
      ),
      body: PineBackground(
        child: Column(
          children: [
            Expanded(
              child: _images.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 80, color: AppColors.outline),
                          const SizedBox(height: 16),
                          const Text('Capture proof of cleaning', style: TextStyle(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_images[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.white),
                                onPressed: () => setState(() => _images.removeAt(index)),
                              ),
                            )
                          ],
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                        child: _isSubmitting 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('SUBMIT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
