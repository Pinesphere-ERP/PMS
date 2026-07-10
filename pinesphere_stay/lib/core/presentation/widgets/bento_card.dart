import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class BentoCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;

  const BentoCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.padding,
    this.clipBehavior = Clip.none,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedScale(
      scale: _isHovered ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: widget.padding ?? const EdgeInsets.all(20),
        clipBehavior: widget.clipBehavior,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(_isHovered ? 0.08 : 0.04),
              offset: Offset(0, _isHovered ? 8 : 4),
              blurRadius: _isHovered ? 16 : 12,
            ),
          ],
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: content,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: content,
    );
  }
}
