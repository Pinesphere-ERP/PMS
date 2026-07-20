import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/onboarding_notifier.dart';

class OwnerRegistrationScreen extends ConsumerStatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  ConsumerState<OwnerRegistrationScreen> createState() => _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends ConsumerState<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _propertyNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _propertyNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(onboardingProvider.notifier).registerOwner(
        ownerName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        businessName: _businessNameController.text.trim(),
        propertyName: _propertyNameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      next.maybeWhen(
        error: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        },
        success: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: Colors.green),
          );
          context.pop(); // Go back to login
        },
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Owner'),
      ),
      body: PineBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: PineCard(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const Text(
                    'Create Your Property',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Owner Details'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                    validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
                    validator: (value) => value == null || value.length < 10 ? 'Enter a valid phone number' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                    validator: (value) => value == null || value.length < 8 ? 'Min 8 characters required' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Business Details'),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(labelText: 'Business / Company Name', prefixIcon: Icon(Icons.business)),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _propertyNameController,
                    decoration: const InputDecoration(labelText: 'Property / Hotel Name', prefixIcon: Icon(Icons.apartment)),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: onboardingState.maybeWhen(
                      loading: () => null,
                      orElse: () => _submit,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: onboardingState.maybeWhen(
                        loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        orElse: () => const Text('Register', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }
}
