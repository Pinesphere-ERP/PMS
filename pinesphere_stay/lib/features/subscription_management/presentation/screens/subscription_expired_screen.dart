import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';

/// Full-screen paywall shown when the subscription has fully expired.
/// Blocks dashboard access until renewed.
class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: PineBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: PineCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.deepOrange.shade300, width: 2),
                        ),
                        child: Icon(Icons.lock_clock_rounded,
                            color: Colors.deepOrange.shade600, size: 40),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Subscription Expired',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your subscription has expired. Renew now to restore full access '
                        'to your property management features.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Feature lock list
                      _LockedFeature(label: 'Guest Check-In & Check-Out'),
                      _LockedFeature(label: 'Booking Management'),
                      _LockedFeature(label: 'Reports & Analytics'),
                      _LockedFeature(label: 'Housekeeping & Maintenance'),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: () => context.go('/subscription'),
                        icon: const Icon(Icons.credit_card_rounded),
                        label: const Text('Renew Subscription'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Allow access to settings and account info even when expired
                          context.go('/settings');
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Account Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedFeature extends StatelessWidget {
  final String label;
  const _LockedFeature({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: Colors.deepOrange.shade300, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}
