import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/owner_onboarding_status.dart';


class OnboardingProgressDashboard extends ConsumerWidget {
  final OwnerOnboardingStatus status;

  const OnboardingProgressDashboard({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Property Setup',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete these steps to unlock full property management.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _buildStatusBanner(context),
          const SizedBox(height: 32),
          _buildActionCard(
            context,
            title: '1. Create Property Profile',
            description: 'Provide basic details, location, and photos.',
            isCompleted: status != OwnerOnboardingStatus.unknown,
            isActive: status == OwnerOnboardingStatus.unknown,
            onTap: () => context.go('/onboarding/property'),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: '2. Super Admin Approval',
            description: 'Wait for our team to verify your details.',
            isCompleted: status.canAccessDashboard || status == OwnerOnboardingStatus.approved,
            isActive: status == OwnerOnboardingStatus.pendingApproval,
            onTap: null,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: '3. Setup Staff & Managers',
            description: 'Invite your team members.',
            isCompleted: false, // For Phase 7
            isActive: status.canAccessDashboard || status == OwnerOnboardingStatus.approved,
            onTap: () => context.go('/staff'),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: '4. Start Trial or Subscribe',
            description: 'Unlock live reservations and sync.',
            isCompleted: status.isFullyOperational,
            isActive: status.needsSubscriptionAction,
            onTap: () => context.go('/subscription'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    Color bannerColor;
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case OwnerOnboardingStatus.pendingApproval:
        bannerColor = Colors.orange;
        icon = Icons.hourglass_empty;
        title = 'Review in Progress';
        subtitle = 'Our team is reviewing your property details. This usually takes 1-2 business days.';
        break;
      case OwnerOnboardingStatus.rejected:
        bannerColor = Colors.red;
        icon = Icons.cancel;
        title = 'Action Required';
        subtitle = 'Your property submission was rejected. Please update your details and resubmit.';
        break;
      case OwnerOnboardingStatus.approved:
      case OwnerOnboardingStatus.trial:
        bannerColor = Colors.green;
        icon = Icons.check_circle;
        title = 'Property Approved!';
        subtitle = 'You can now invite staff and set up your rooms. Enjoy your trial period!';
        break;
      case OwnerOnboardingStatus.trialExpired:
      case OwnerOnboardingStatus.subscriptionExpired:
        bannerColor = Colors.red;
        icon = Icons.payment;
        title = 'Subscription Required';
        subtitle = 'Your trial or subscription has ended. Please subscribe to continue using Pinesphere Stay.';
        break;
      case OwnerOnboardingStatus.suspended:
        bannerColor = Colors.red;
        icon = Icons.block;
        title = 'Account Suspended';
        subtitle = 'Your account has been suspended. Please contact support.';
        break;
      default:
        bannerColor = Colors.blue;
        icon = Icons.info;
        title = 'Welcome to Pinesphere!';
        subtitle = 'Let\'s get your property set up.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: bannerColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required bool isCompleted,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    final color = isCompleted
        ? Colors.green
        : isActive
            ? Theme.of(context).primaryColor
            : Colors.grey.shade400;

    return Card(
      elevation: isActive ? 4 : 0,
      color: isActive ? Colors.white : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isActive ? color : Colors.grey.shade200, width: isActive ? 2 : 1),
      ),
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompleted || isActive ? AppColors.onBackground : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive && onTap != null)
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
