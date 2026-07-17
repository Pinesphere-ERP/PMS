import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinesphere_stay/core/theme/app_colors.dart';
import 'package:dio/dio.dart';

// Very basic auth state for guest portal
class GuestTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setToken(String? token) => state = token;
}
final guestTokenProvider = NotifierProvider<GuestTokenNotifier, String?>(GuestTokenNotifier.new);

class GuestBookingIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setId(String? id) => state = id;
}
final guestBookingIdProvider = NotifierProvider<GuestBookingIdNotifier, String?>(GuestBookingIdNotifier.new);

class GuestNameNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setName(String? name) => state = name;
}
final guestNameProvider = NotifierProvider<GuestNameNotifier, String?>(GuestNameNotifier.new);

class PortalLoginScreen extends ConsumerStatefulWidget {
  const PortalLoginScreen({super.key});

  @override
  ConsumerState<PortalLoginScreen> createState() => _PortalLoginScreenState();
}

class _PortalLoginScreenState extends ConsumerState<PortalLoginScreen> {
  final _bookingRefController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: const String.fromEnvironment('API_URL', defaultValue: 'https://pms-bvko.onrender.com/api/v1')));
      final res = await dio.post('/portal/auth', data: {
        'booking_reference': _bookingRefController.text.trim(),
        'mobile_number': _mobileController.text.trim(),
      });
      
      final token = res.data['access_token'];
      final guestName = res.data['guest_name'];
      final bookingId = res.data['booking_id'];
      
      ref.read(guestTokenProvider.notifier).setToken(token);
      ref.read(guestNameProvider.notifier).setName(guestName);
      ref.read(guestBookingIdProvider.notifier).setId(bookingId);
      
      if (mounted) context.go('/portal/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid booking reference or mobile number')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hotel, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Guest Portal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your booking details to access room service, your folio, and more.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _bookingRefController,
                decoration: InputDecoration(
                  labelText: 'Booking Reference',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Access Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
