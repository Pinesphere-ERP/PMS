import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/session_context.dart';
import '../../../../core/auth/owner_onboarding_status.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/subscription_notifier.dart';
import '../../domain/models/subscription_model.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription Management', style: TextStyle(color: AppColors.onBackground)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onBackground),
      ),
      floatingActionButton: subState.when(
        data: (subscription) {
          if (subscription != null && subscription.isActive) {
            return FloatingActionButton.extended(
              onPressed: () {
                ref.read(sessionContextProvider.notifier).overrideOwnerStatus(OwnerOnboardingStatus.active);
                context.go('/dashboard');
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Proceed to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            );
          }
          return const SizedBox.shrink();
        },
        loading: () => const SizedBox.shrink(),
        error: (error, stackTrace) => const SizedBox.shrink(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Active Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            subState.when(
              data: (subscription) {
                if (subscription == null) {
                  return const Text('No active subscription found.');
                }
                final isActive = subscription.isActive;
                final isTrial = subscription.isTrial;
                return PineCard(
                  backgroundColor: AppColors.primaryContainer,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${subscription.plan} Plan ${isTrial ? "(Trial)" : ""}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.onPrimaryContainer.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              subscription.status,
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        subscription.billingCycle,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Renews on: ${subscription.expiryDate.split("T").first}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showCancelDialog(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.onPrimaryContainer,
                            foregroundColor: AppColors.primaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Text('Error loading subscription: $err'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Available Plans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            _buildPlansList(context, ref),
            const SizedBox(height: 32),
            const Text(
              'Billing History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            PineCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.outlineVariant),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                    title: Text('Invoice #INV-${2026 - index}0812', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('12 Aug ${2026 - index}', style: const TextStyle(color: AppColors.onSurfaceVariant)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('₹ 15,000', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.download, size: 20, color: AppColors.outline),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          return const Text('No plans available.');
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            final subState = ref.read(subscriptionProvider).value;
            final isCurrent = subState != null && plan.name.toLowerCase() == subState.plan.toLowerCase();
            return _buildPlanItem(context, ref, plan, isCurrent);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading plans: $e'),
    );
  }

  Widget _buildPlanItem(
      BuildContext context, WidgetRef ref, SubscriptionPlanModel plan, bool isCurrent) {
    return PineCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: isCurrent ? AppColors.primaryContainer.withValues(alpha: 0.2) : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.primary : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${plan.amount}/mo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan.features,
            style: const TextStyle(color: AppColors.outline),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent
                  ? null
                  : () => _upgradePlan(context, ref, plan.name),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? AppColors.surfaceContainerHigh : AppColors.primary,
                foregroundColor: isCurrent ? AppColors.outline : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isCurrent ? 'Current Plan' : 'Upgrade'),
            ),
          ),
        ],
      ),
    );
  }

  void _upgradePlan(BuildContext context, WidgetRef ref, String planName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final url = await ref.read(subscriptionProvider.notifier).upgradePlan(planName);
    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading
      if (url == 'placeholder_success') {
        // Refresh session to update router guards (paymentPending -> active)
        ref.read(sessionContextProvider.notifier).overrideOwnerStatus(OwnerOnboardingStatus.active);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Welcome to Pinesphere.')),
        );
        // Router will automatically redirect to dashboard because status is active!
        context.go('/dashboard');
      } else if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open checkout page')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate checkout')),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
            'Are you sure you want to cancel? You will retain access until the end of your billing cycle.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Plan'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(subscriptionProvider.notifier)
                  .cancelSubscription();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscription cancelled')),
                );
              }
            },
            child: const Text('Cancel Subscription', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
