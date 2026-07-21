import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/ambient_forest_glow.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_notifier.dart';
import '../../../../core/permissions/user_role.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  late final AnimationController _shakeController;
  UserRole _selectedRole = UserRole.owner;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _addNumber(String num) {
    if (_pin.length < 4) {
      setState(() => _pin += num);
      HapticFeedback.lightImpact();
      if (_pin.length == 4) {
        _handleLogin();
      }
    }
  }

  void _deleteNumber() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
      HapticFeedback.lightImpact();
    }
  }

  void _biometricAction() {
    // Placeholder
  }

  void _handleLogin() {
    // Forward the pin to the actual offline/online auth notifier
    ref.read(authProvider.notifier).loginWithPin(_pin);
  }

  @override
  Widget build(BuildContext context) {
    // Note: We don't use ref.listen to navigate. The GoRouter redirect in app_router.dart handles it!
    // We only listen for errors.
    ref.listen<AuthState>(authProvider, (previous, next) {
      next.maybeWhen(
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          _shakeController.forward(from: 0).then((_) {
            setState(() => _pin = '');
          });
        },
        orElse: () {},
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          const AmbientForestGlow(),
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader(context),
                    _buildPinDisplay(),
                    _buildKeypad(context),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.network(
              'https://lh3.googleusercontent.com/aida/AP1WRLsNZfpr3SqCh2qriKKtYjH3uwarOjm8WmUIl71HNz8fYek1c5NKdyXhRSPtmTbLkKFU775bH_e2t5xTAHDFce_0YZTY-D26wL-oUlvXoJHFIu7BgyA6yZFUMgK4P0KfUJbWXascFNRKodev-4l532l1SA6F-NJ8SStFQQLLv_RI-t95BeAkN2cFYlnXuR7SC9oZ2zlaWLIsmcHu_z01tIoyhkn5Mczc6MUYcROmCzq3Qo6Y3-WAZ_tpnPc',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.hotel, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 24),
        DropdownButton<UserRole>(
          value: _selectedRole,
          dropdownColor: AppColors.surface,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary),
          underline: Container(height: 2, color: AppColors.primary),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: UserRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text('Login as: ${role.displayName}'),
            );
          }).toList(),
          onChanged: (role) {
            if (role != null) {
              setState(() => _selectedRole = role);
            }
          },
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);
            final userName = authState.maybeWhen(
              locked: (user) => user.name,
              authenticated: (user) => user.name,
              orElse: () => 'User',
            );
            return Text(
              'Welcome back, $userName',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
              textAlign: TextAlign.center,
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your PIN to access the property',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPinDisplay() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = Curves.easeInOutSine.transform(_shakeController.value) * 20;
        final dx = (_shakeController.value < 0.2) ? offset 
                 : (_shakeController.value < 0.4) ? -offset 
                 : (_shakeController.value < 0.6) ? offset 
                 : (_shakeController.value < 0.8) ? -offset : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.primary : AppColors.surfaceContainerHigh,
                  border: Border.all(
                    color: isFilled ? AppColors.primary : AppColors.outlineVariant,
                    width: 2,
                  ),
                ),
                // ignore: deprecated_member_use
                transform: Matrix4.identity()..scale(isFilled ? 1.1 : 1.0),
                transformAlignment: Alignment.center,
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return SizedBox(
      width: 280, // constrains the 3x4 grid nicely
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 32,
        childAspectRatio: 1,
        children: [
          for (var i = 1; i <= 9; i++) _KeypadButton(text: '$i', onTap: () => _addNumber('$i')),
          _KeypadButton(
            icon: Icons.fingerprint,
            iconColor: AppColors.primary,
            onTap: _biometricAction,
          ),
          _KeypadButton(text: '0', onTap: () => _addNumber('0')),
          _KeypadButton(
            icon: Icons.backspace_outlined,
            iconColor: AppColors.onSurfaceVariant,
            onTap: _deleteNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_done_rounded, size: 18, color: AppColors.onSecondaryContainer),
              const SizedBox(width: 8),
              Text(
                'Offline-first Sync Active',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSecondaryContainer,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'V2.4.0-STABLE',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.outline,
                letterSpacing: 2.0,
              ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _KeypadButton({
    this.text,
    this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed ? AppColors.secondaryContainer : Colors.transparent,
        ),
        transform: Matrix4.diagonal3Values(_isPressed ? 0.92 : 1.0, _isPressed ? 0.92 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        alignment: Alignment.center,
        child: widget.icon != null
            ? Icon(widget.icon, size: 28, color: widget.iconColor)
            : Text(
                widget.text!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 28,
                    ),
              ),
      ),
    );
  }
}
