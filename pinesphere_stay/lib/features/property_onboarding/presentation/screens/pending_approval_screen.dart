import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';

/// Shown when the property is in PENDING_APPROVAL state.
/// Owner waits here until Super Admin approves or rejects.
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          color: Colors.amber.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber.shade300, width: 2),
                        ),
                        child: Icon(Icons.hourglass_top_rounded,
                            color: Colors.amber.shade600, size: 40),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Property Under Review',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your property registration is being reviewed by our team. '
                        'We\'ll notify you once approved. This typically takes 1–2 business days.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Trial banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, color: Colors.green.shade700, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your 14-Day Trial Is Active',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You can explore the platform while your application is reviewed.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _StatusStep(
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                        label: 'Registration Submitted',
                        isComplete: true,
                      ),
                      _StatusStep(
                        icon: Icons.pending_rounded,
                        color: Colors.amber,
                        label: 'Admin Review (In Progress)',
                        isComplete: false,
                      ),
                      _StatusStep(
                        icon: Icons.radio_button_unchecked_rounded,
                        color: Colors.grey,
                        label: 'Property Approved',
                        isComplete: false,
                      ),
                      const SizedBox(height: 28),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/dashboard'),
                        icon: const Icon(Icons.explore_outlined),
                        label: const Text('Explore Platform'),
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

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isComplete;

  const _StatusStep({
    required this.icon,
    required this.color,
    required this.label,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isComplete ? Colors.black87 : Colors.grey.shade500,
              fontWeight: isComplete ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
