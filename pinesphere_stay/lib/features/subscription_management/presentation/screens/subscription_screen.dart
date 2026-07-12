import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../../core/theme/app_colors.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription Management', style: TextStyle(color: AppColors.onBackground)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onBackground),
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
            BentoCard(
              backgroundColor: AppColors.primaryContainer,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pro Plan (Yearly)',
                        style: TextStyle(
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
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '₹ 15,000 / year',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Renews on: 12 Aug 2027',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.onPrimaryContainer,
                        foregroundColor: AppColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Manage Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
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
            Row(
              children: [
                Expanded(
                  child: BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Basic',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '₹ 5,000 / year',
                          style: TextStyle(fontSize: 16, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text('• Up to 50 rooms\n• Basic Reports\n• Standard Support', style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.5)),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Downgrade'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enterprise',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Contact Us',
                          style: TextStyle(fontSize: 16, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text('• Unlimited rooms\n• Custom Reports\n• 24/7 Dedicated Support', style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.5)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Upgrade'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
            BentoCard(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
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
}
