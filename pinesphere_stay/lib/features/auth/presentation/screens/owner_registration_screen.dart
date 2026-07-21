import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/onboarding_notifier.dart';

const _propertyTypes = [
  'HOTEL',
  'RESORT',
  'HOSTEL',
  'GUESTHOUSE',
  'MOTEL',
  'BOUTIQUE_HOTEL',
  'SERVICE_APARTMENT',
  'VILLA',
  'FARMHOUSE',
  'OTHER',
];

const _propertyTypeLabels = {
  'HOTEL': 'Hotel',
  'RESORT': 'Resort',
  'HOSTEL': 'Hostel',
  'GUESTHOUSE': 'Guest House',
  'MOTEL': 'Motel',
  'BOUTIQUE_HOTEL': 'Boutique Hotel',
  'SERVICE_APARTMENT': 'Service Apartment',
  'VILLA': 'Villa',
  'FARMHOUSE': 'Farmhouse',
  'OTHER': 'Other',
};

class OwnerRegistrationScreen extends ConsumerStatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  ConsumerState<OwnerRegistrationScreen> createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState
    extends ConsumerState<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1 — Owner Details
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Page 2 — Property Details
  final _businessNameController = TextEditingController();
  final _propertyNameController = TextEditingController();
  String _selectedPropertyType = 'HOTEL';
  int _starCategory = 3;
  bool _acceptedTos = false;

  // Password strength
  double _passwordStrength = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _propertyNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  double _calculateStrength(String p) {
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (p.length >= 12) s += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.2;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.2;
    if (RegExp(r'[!@#\$&*~%^()]').hasMatch(p)) s += 0.2;
    return s.clamp(0.0, 1.0);
  }

  Color _strengthColor(double s) {
    if (s < 0.4) return Colors.red;
    if (s < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _strengthLabel(double s) {
    if (s < 0.4) return 'Weak';
    if (s < 0.7) return 'Fair';
    return 'Strong';
  }

  bool _validatePage1() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.length < 2) {
      _showError('Full name must be at least 2 characters.');
      return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showError('Enter a valid email address.');
      return false;
    }
    if (phone.length < 10) {
      _showError('Enter a valid 10-digit mobile number.');
      return false;
    }
    if (pass.length < 8) {
      _showError('Password must be at least 8 characters.');
      return false;
    }
    if (pass != confirm) {
      _showError('Passwords do not match.');
      return false;
    }
    return true;
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (!_validatePage1()) return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTos) {
      _showError('Please accept the Terms of Service to continue.');
      return;
    }
    if (_businessNameController.text.trim().isEmpty) {
      _showError('Business name is required.');
      return;
    }
    if (_propertyNameController.text.trim().isEmpty) {
      _showError('Property name is required.');
      return;
    }
    ref.read(onboardingProvider.notifier).registerOwner(
          ownerName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          mobileNumber: _phoneController.text.trim(),
          password: _passwordController.text,
          businessName: _businessNameController.text.trim(),
          propertyName: _propertyNameController.text.trim(),
          propertyType: _selectedPropertyType,
          starCategory: _starCategory,
        );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      next.maybeWhen(
        error: (msg) => _showError(msg),
        success: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  '✅ Registration successful! Your trial is now active.'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
          context.go('/login');
        },
        orElse: () {},
      );
    });

    return Scaffold(
      body: PineBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_currentPage == 0) {
                          context.pop();
                        } else {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Your Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Step indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Step ${_currentPage + 1} of 2',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress bar ─────────────────────────────────────────────
              LinearProgressIndicator(
                value: (_currentPage + 1) / 2,
                minHeight: 3,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary),
              ),

              // ── Pages ────────────────────────────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildPage1(theme),
                      _buildPage2(theme, onboardingState),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: PineCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                    icon: Icons.person_outline_rounded, title: 'Owner Details'),
                const SizedBox(height: 20),
                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.name,
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'At least 2 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v?.contains('@') == true) ? null : 'Invalid email',
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _phoneController,
                  label: 'Mobile Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v?.length ?? 0) >= 10 ? null : 'Invalid number',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (v) => setState(
                      () => _passwordStrength = _calculateStrength(v)),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      (v?.length ?? 0) >= 8 ? null : 'Min 8 characters',
                ),
                const SizedBox(height: 8),
                // Password strength bar
                if (_passwordController.text.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _passwordStrength,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _strengthColor(_passwordStrength)),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _strengthLabel(_passwordStrength),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _strengthColor(_passwordStrength),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v == _passwordController.text
                      ? null
                      : 'Passwords do not match',
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Next: Property Details'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage2(ThemeData theme, OnboardingState onboardingState) {
    final isLoading = onboardingState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: PineCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                    icon: Icons.business_outlined, title: 'Property Details'),
                const SizedBox(height: 20),
                _buildField(
                  controller: _businessNameController,
                  label: 'Business / Company Name',
                  icon: Icons.domain_outlined,
                  validator: (v) =>
                      (v?.trim().isEmpty == true) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _propertyNameController,
                  label: 'Property / Hotel Name',
                  icon: Icons.apartment_rounded,
                  validator: (v) =>
                      (v?.trim().isEmpty == true) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Property Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedPropertyType,
                  decoration: InputDecoration(
                    labelText: 'Property Type',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _propertyTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_propertyTypeLabels[t] ?? t),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPropertyType = v);
                  },
                ),
                const SizedBox(height: 16),

                // Star Category Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Star Category',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (i) => GestureDetector(
                          onTap: () => setState(() => _starCategory = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              i < _starCategory
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '$_starCategory Star',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Terms of Service
                InkWell(
                  onTap: () =>
                      setState(() => _acceptedTos = !_acceptedTos),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _acceptedTos,
                          onChanged: (v) =>
                              setState(() => _acceptedTos = v ?? false),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodySmall,
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' & '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Trial notice banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You\'ll get a 14-day free trial after registration. '
                          'No credit card required.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account & Start Free Trial',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: validator,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
